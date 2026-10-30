//
//  PersonRepositoryTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

private final class PersonStubNetworkService: TMDBNetworkServiceProtocol, @unchecked Sendable {
    var responses: [String: Data] = [:]
    var requestedEndpoints: [TMDBEndpoint] = []
    var error: Error?

    func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        requestedEndpoints.append(endpoint)
        if let error {
            throw error
        }
        guard let data = responses[endpoint.path] else {
            throw URLError(.badServerResponse)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

struct PersonRepositoryTests {

    private func makeSUT() -> (MovieRepositoryImpl, PersonStubNetworkService) {
        let network = PersonStubNetworkService()
        let repository = MovieRepositoryImpl(
            networkService: network,
            localDataSource: SwiftDataFavoriteDataSource.createInMemory(),
            regionCodeProvider: { "US" }
        )
        return (repository, network)
    }

    private static func credit(
        id: Int,
        title: String,
        releaseDate: String?,
        character: String = "Role",
        posterPath: String? = nil,
        voteAverage: Double = 7.0,
        voteCount: Int = 100
    ) -> [String: Any] {
        var entry: [String: Any] = [
            "id": id,
            "title": title,
            "vote_average": voteAverage,
            "vote_count": voteCount,
            "character": character
        ]
        if let releaseDate {
            entry["release_date"] = releaseDate
        }
        if let posterPath {
            entry["poster_path"] = posterPath
        }
        return entry
    }

    private static func personJSON(
        id: Int = 31,
        name: String = "Tom Hanks",
        profilePath: String? = nil,
        department: String? = "Acting",
        birthday: String? = nil,
        deathday: String? = nil,
        placeOfBirth: String? = nil,
        biography: String? = nil,
        cast: [[String: Any]]? = nil,
        crew: [[String: Any]]? = nil
    ) throws -> Data {
        var payload: [String: Any] = [
            "id": id,
            "name": name
        ]
        if let profilePath {
            payload["profile_path"] = profilePath
        }
        if let department {
            payload["known_for_department"] = department
        }
        if let birthday {
            payload["birthday"] = birthday
        }
        if let deathday {
            payload["deathday"] = deathday
        }
        if let placeOfBirth {
            payload["place_of_birth"] = placeOfBirth
        }
        if let biography {
            payload["biography"] = biography
        }

        var movieCredits: [String: Any] = [:]
        if let cast {
            movieCredits["cast"] = cast
        }
        if let crew {
            movieCredits["crew"] = crew
        }
        payload["movie_credits"] = movieCredits

        return try JSONSerialization.data(withJSONObject: payload)
    }

    @Test func personRequestUsesPersonPathAndAppendsMovieCredits() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON()

        _ = try await repository.getPersonProfile(id: 31)

        let endpoint = try #require(network.requestedEndpoints.first)
        #expect(endpoint.path == "/person/31")

        let request = try endpoint.makeURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let appendValue = components.queryItems?
            .first { $0.name == "append_to_response" }?
            .value
        #expect(appendValue == "movie_credits")
    }

    @Test func profileMapsIdentityAndDepartment() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(
            id: 31,
            name: "Tom Hanks",
            profilePath: "/tom.jpg",
            department: "Acting"
        )

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.id == 31)
        #expect(profile.name == "Tom Hanks")
        #expect(profile.profilePath == "/tom.jpg")
        #expect(profile.knownForDepartment == "Acting")
    }

    @Test func creditsUseCastOnlyAndMapMovieFields() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(
            cast: [
                Self.credit(
                    id: 13,
                    title: "Forrest Gump",
                    releaseDate: "1994-06-23",
                    character: "Forrest Gump",
                    posterPath: "/gump.jpg"
                )
            ],
            crew: [
                Self.credit(id: 99, title: "Crew Movie", releaseDate: "2001-01-01")
            ]
        )

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.count == 1)
        let credit = try #require(profile.credits.first)
        #expect(credit.id == 13)
        #expect(credit.title == "Forrest Gump")
        #expect(credit.character == "Forrest Gump")
        #expect(credit.posterPath == "/gump.jpg")
        #expect(credit.releaseYear == "1994")
        #expect(credit.voteAverage == 7.0)
        #expect(credit.voteCount == 100)
    }

    @Test func creditsExcludeMissingAndFutureReleaseDates() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: [
            Self.credit(id: 1, title: "No Date", releaseDate: nil),
            Self.credit(id: 2, title: "Future", releaseDate: "2999-01-01"),
            Self.credit(id: 3, title: "Released", releaseDate: "1994-06-23")
        ])

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.map(\.id) == [3])
    }

    @Test func creditsCollapseDuplicateMovieIds() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: [
            Self.credit(id: 13, title: "Forrest Gump", releaseDate: "1994-06-23", character: "Forrest Gump"),
            Self.credit(id: 13, title: "Forrest Gump", releaseDate: "1994-06-23", character: "Narrator")
        ])

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.count == 1)
        #expect(profile.credits.first?.character == "Forrest Gump")
    }

    @Test func creditsSortByReleaseDateDescending() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: [
            Self.credit(id: 1, title: "Oldest", releaseDate: "1994-06-23"),
            Self.credit(id: 2, title: "Newest", releaseDate: "2020-01-01"),
            Self.credit(id: 3, title: "Middle", releaseDate: "2010-05-05")
        ])

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.map(\.id) == [2, 3, 1])
    }

    @Test func creditsSortByTitleAscendingWhenReleaseDatesMatch() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: [
            Self.credit(id: 1, title: "Zulu", releaseDate: "2010-05-05"),
            Self.credit(id: 2, title: "Alpha", releaseDate: "2010-05-05")
        ])

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.map(\.title) == ["Alpha", "Zulu"])
    }

    @Test func profileIsCachedForSamePerson() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON()

        _ = try await repository.getPersonProfile(id: 31)
        _ = try await repository.getPersonProfile(id: 31)

        #expect(network.requestedEndpoints.count == 1)
    }

    @Test func profileWithoutMovieCreditsHasNoCredits() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: nil)

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.isEmpty)
    }

    @Test func profileMapsBiographyAndPersonalDetails() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(
            birthday: "1956-07-09",
            deathday: "2020-01-01",
            placeOfBirth: "Concord, California, USA",
            biography: "Thomas Jeffrey Hanks is an American actor and filmmaker."
        )

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.birthday == "1956-07-09")
        #expect(profile.deathday == "2020-01-01")
        #expect(profile.placeOfBirth == "Concord, California, USA")
        #expect(profile.biography == "Thomas Jeffrey Hanks is an American actor and filmmaker.")
    }

    @Test func profileDefaultsMissingPersonalDetails() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(
            birthday: nil,
            deathday: nil,
            placeOfBirth: nil,
            biography: nil
        )

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.birthday == nil)
        #expect(profile.deathday == nil)
        #expect(profile.placeOfBirth == nil)
        #expect(profile.biography.isEmpty)
    }

    @Test func malformedCreditEntriesAreIgnored() async throws {
        let (repository, network) = makeSUT()
        network.responses["/person/31"] = try Self.personJSON(cast: [
            ["character": "No id", "release_date": "2000-01-01"],
            Self.credit(id: 42, title: "", releaseDate: "2000-01-01"),
            Self.credit(id: 43, title: "Valid", releaseDate: "2000-01-01")
        ])

        let profile = try await repository.getPersonProfile(id: 31)

        #expect(profile.credits.map(\.id) == [43])
    }
}
