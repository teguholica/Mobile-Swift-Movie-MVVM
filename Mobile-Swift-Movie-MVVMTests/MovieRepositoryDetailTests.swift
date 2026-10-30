//
//  MovieRepositoryDetailTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

private final class DetailStubNetworkService: TMDBNetworkServiceProtocol, @unchecked Sendable {
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

struct MovieRepositoryDetailTests {

    private func makeSUT(regionProvider: @escaping @Sendable () -> String) -> (MovieRepositoryImpl, DetailStubNetworkService) {
        let network = DetailStubNetworkService()
        let repository = MovieRepositoryImpl(
            networkService: network,
            localDataSource: SwiftDataFavoriteDataSource.createInMemory(),
            regionCodeProvider: regionProvider
        )
        return (repository, network)
    }

    private func makeSUT(region: String = "US") -> (MovieRepositoryImpl, DetailStubNetworkService) {
        makeSUT(regionProvider: { region })
    }

    private final class LockedRegion: @unchecked Sendable {
        private let lock = NSLock()
        private var value: String

        init(_ value: String) {
            self.value = value
        }

        func get() -> String {
            lock.lock()
            defer { lock.unlock() }
            return value
        }

        func set(_ newValue: String) {
            lock.lock()
            value = newValue
            lock.unlock()
        }
    }

    private static func detailJSON(
        id: Int = 603,
        videos: [[String: Any]]? = nil,
        credits: [[String: Any]]? = nil,
        watchProviders: [String: Any]? = nil,
        recommendations: [[String: Any]]? = nil,
        similar: [[String: Any]]? = nil
    ) throws -> Data {
        var payload: [String: Any] = [
            "id": id,
            "title": "The Matrix"
        ]
        if let videos {
            payload["videos"] = ["results": videos]
        }
        if let credits {
            payload["credits"] = ["cast": credits]
        }
        if let watchProviders {
            payload["watch/providers"] = ["results": watchProviders]
        }
        if let recommendations {
            payload["recommendations"] = ["page": 1, "results": recommendations]
        }
        if let similar {
            payload["similar"] = ["page": 1, "results": similar]
        }
        return try JSONSerialization.data(withJSONObject: payload)
    }

    private static func movieJSON(id: Int, title: String) -> [String: Any] {
        ["id": id, "title": title]
    }

    private static func provider(
        id: Int,
        name: String,
        logoPath: String = "/logo.png",
        displayPriority: Int = 0
    ) -> [String: Any] {
        [
            "provider_id": id,
            "provider_name": name,
            "logo_path": logoPath,
            "display_priority": displayPriority
        ]
    }

    private static func regionEntry(
        link: String,
        flatrate: [[String: Any]]? = nil,
        free: [[String: Any]]? = nil,
        ads: [[String: Any]]? = nil,
        rent: [[String: Any]]? = nil,
        buy: [[String: Any]]? = nil
    ) -> [String: Any] {
        var entry: [String: Any] = ["link": link]
        if let flatrate { entry["flatrate"] = flatrate }
        if let free { entry["free"] = free }
        if let ads { entry["ads"] = ads }
        if let rent { entry["rent"] = rent }
        if let buy { entry["buy"] = buy }
        return entry
    }

    private static func castMember(
        id: Int,
        name: String,
        character: String,
        order: Int,
        profilePath: String? = nil
    ) -> [String: Any] {
        var member: [String: Any] = [
            "id": id,
            "name": name,
            "character": character,
            "order": order
        ]
        if let profilePath {
            member["profile_path"] = profilePath
        }
        return member
    }

    private static func video(
        id: String,
        key: String,
        site: String = "YouTube",
        type: String,
        official: Bool
    ) -> [String: Any] {
        [
            "id": id,
            "key": key,
            "name": "\(type) video",
            "site": site,
            "type": type,
            "official": official
        ]
    }

    @Test func detailRequestsVideosAndSelectsOfficialTrailer() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: [
            Self.video(id: "f1", key: "featurette", type: "Featurette", official: true),
            Self.video(id: "t1", key: "teaser", type: "Teaser", official: true),
            Self.video(id: "tr1", key: "official-trailer", type: "Trailer", official: true)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.trailer?.key == "official-trailer")

        let endpoint = try #require(network.requestedEndpoints.first)
        #expect(endpoint.path == "/movie/603")
        let request = try endpoint.makeURLRequest()
        let url = try #require(request.url)
        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let appendValue = components.queryItems?
            .first { $0.name == "append_to_response" }?
            .value ?? ""
        #expect(appendValue.split(separator: ",").map(String.init).contains("videos"))
    }

    @Test func selectsOfficialTeaserWhenNoOfficialTrailer() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: [
            Self.video(id: "f1", key: "featurette", type: "Featurette", official: true),
            Self.video(id: "t1", key: "official-teaser", type: "Teaser", official: true)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.trailer?.key == "official-teaser")
    }

    @Test func selectsAnyYouTubeVideoWhenNoTrailerOrTeaser() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: [
            Self.video(id: "f1", key: "featurette", type: "Featurette", official: false)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.trailer?.key == "featurette")
    }

    @Test func noTrailerWhenOnlyNonYouTubeVideos() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: [
            Self.video(id: "v1", key: "vimeo-trailer", site: "Vimeo", type: "Trailer", official: true)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.trailer == nil)
    }

    @Test func noTrailerWhenVideosAreAbsent() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: nil)

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.trailer == nil)
    }

    @Test func malformedVideoEntryDoesNotFailDetailDecoding() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(videos: [
            ["id": "broken", "site": "YouTube", "official": true],
            Self.video(id: "tr1", key: "official-trailer", type: "Trailer", official: true)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.title == "The Matrix")
        #expect(detail.trailer?.key == "official-trailer")
    }

    @Test func castIsDecodedSortedByOrderAndLimitedToTen() async throws {
        let (repository, network) = makeSUT()
        let members = (1...12).reversed().map { index in
            Self.castMember(
                id: index,
                name: "Actor \(index)",
                character: "Character \(index)",
                order: index
            )
        }
        network.responses["/movie/603"] = try Self.detailJSON(credits: members)

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.cast.count == 10)
        #expect(detail.cast.map(\.id) == Array(1...10))
        #expect(detail.cast.first?.name == "Actor 1")
    }

    @Test func castIgnoresMalformedEntries() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(credits: [
            ["character": "Nameless", "order": 0],
            Self.castMember(id: 6384, name: "Keanu Reeves", character: "Neo", order: 1)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.cast.count == 1)
        #expect(detail.cast.first?.name == "Keanu Reeves")
    }

    @Test func castIsEmptyWhenCreditsAreAbsent() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON()

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.cast.isEmpty)
    }

    @Test func providersUseInjectedRegion() async throws {
        let (repository, network) = makeSUT(region: "ID")
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US",
                flatrate: [Self.provider(id: 8, name: "Netflix")]
            ),
            "ID": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=ID",
                flatrate: [Self.provider(id: 159, name: "Catchplay")],
                rent: [Self.provider(id: 2, name: "Apple TV Store")]
            )
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.providers?.link?.absoluteString.contains("locale=ID") == true)
        #expect(detail.providers?.groups.first?.kind == .stream)
        #expect(detail.providers?.groups.first?.providers.first?.name == "Catchplay")
    }

    @Test func providerGroupsFollowDisplayOrder() async throws {
        let (repository, network) = makeSUT(region: "US")
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US",
                flatrate: [Self.provider(id: 1, name: "Streaming")],
                free: [Self.provider(id: 2, name: "Free")],
                ads: [Self.provider(id: 3, name: "Ads")],
                rent: [Self.provider(id: 4, name: "Rent")],
                buy: [Self.provider(id: 5, name: "Buy")]
            )
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.providers?.groups.map(\.kind) == [.stream, .free, .ads, .rent, .buy])
    }

    @Test func providersAreNilWhenRegionHasNoEntry() async throws {
        let (repository, network) = makeSUT(region: "ID")
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US",
                flatrate: [Self.provider(id: 8, name: "Netflix")]
            )
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.providers == nil)
    }

    @Test func malformedProviderEntryDoesNotFailDetail() async throws {
        let (repository, network) = makeSUT(region: "US")
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US",
                flatrate: [
                    ["provider_id": 999],
                    Self.provider(id: 8, name: "Netflix")
                ]
            )
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.providers?.groups.first?.providers.map(\.name) == ["Netflix"])
    }

    @Test func recommendedMoviesPreferRecommendationsOverSimilar() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(
            recommendations: [Self.movieJSON(id: 901, title: "Recommended")],
            similar: [Self.movieJSON(id: 902, title: "Similar")]
        )

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.recommendedMovies.map(\.id) == [901])
    }

    @Test func recommendedMoviesFallBackToSimilar() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(
            recommendations: [],
            similar: [Self.movieJSON(id: 902, title: "Similar")]
        )

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.recommendedMovies.map(\.id) == [902])
    }

    @Test func recommendedMoviesExcludeCurrentMovie() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(
            recommendations: [
                Self.movieJSON(id: 603, title: "The Matrix"),
                Self.movieJSON(id: 901, title: "Recommended")
            ]
        )

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.recommendedMovies.map(\.id) == [901])
    }

    @Test func recommendedMoviesAreEmptyWhenBothSourcesAbsent() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON()

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.recommendedMovies.isEmpty)
    }

    @Test func detailIsCachedForSameMovieAndRegion() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON()

        _ = try await repository.getMovieDetails(id: 603)
        _ = try await repository.getMovieDetails(id: 603)

        #expect(network.requestedEndpoints.count == 1)
    }

    @Test func cacheSeparatesRegions() async throws {
        let region = LockedRegion("US")
        let (repository, network) = makeSUT(regionProvider: { region.get() })
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US",
                flatrate: [Self.provider(id: 8, name: "Netflix")]
            ),
            "ID": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=ID",
                flatrate: [Self.provider(id: 159, name: "Catchplay")]
            )
        ])

        let usDetail = try await repository.getMovieDetails(id: 603)
        region.set("ID")
        let idDetail = try await repository.getMovieDetails(id: 603)

        #expect(network.requestedEndpoints.count == 2)
        #expect(usDetail.providers?.link?.absoluteString.contains("locale=US") == true)
        #expect(idDetail.providers?.link?.absoluteString.contains("locale=ID") == true)
    }

    @Test func providersWithLinkButNoGroupsStillExposeLink() async throws {
        let (repository, network) = makeSUT(region: "US")
        network.responses["/movie/603"] = try Self.detailJSON(watchProviders: [
            "US": Self.regionEntry(
                link: "https://www.themoviedb.org/movie/603/watch?locale=US"
            )
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.providers?.groups.isEmpty == true)
        #expect(detail.providers?.link?.absoluteString.contains("locale=US") == true)
    }

    @Test func recommendedMoviesFallBackToSimilarWhenRecommendationsOnlyContainCurrent() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(
            recommendations: [Self.movieJSON(id: 603, title: "The Matrix")],
            similar: [Self.movieJSON(id: 902, title: "Similar")]
        )

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.recommendedMovies.map(\.id) == [902])
    }

    @Test func castEntriesWithSamePersonHaveDistinctIdentity() async throws {
        let (repository, network) = makeSUT()
        network.responses["/movie/603"] = try Self.detailJSON(credits: [
            Self.castMember(id: 6384, name: "Keanu Reeves", character: "Neo", order: 0),
            Self.castMember(id: 6384, name: "Keanu Reeves", character: "Thomas Anderson", order: 1)
        ])

        let detail = try await repository.getMovieDetails(id: 603)

        #expect(detail.cast.count == 2)
        #expect(Set(detail.cast.map(\.uniqueID)).count == 2)
    }
}
