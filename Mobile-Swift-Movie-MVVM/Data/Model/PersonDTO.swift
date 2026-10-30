//
//  PersonDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct PersonDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let knownForDepartment: String?
    public let birthday: String?
    public let deathday: String?
    public let placeOfBirth: String?
    public let biography: String?
    public let movieCredits: PersonMovieCreditsDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case birthday
        case deathday
        case placeOfBirth = "place_of_birth"
        case biography
        case movieCredits = "movie_credits"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        self.birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        self.deathday = try container.decodeIfPresent(String.self, forKey: .deathday)
        self.placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
        self.biography = try container.decodeIfPresent(String.self, forKey: .biography)
        self.movieCredits = try container.decodeIfPresent(PersonMovieCreditsDTO.self, forKey: .movieCredits)
    }

    public func toDomain(credits: [PersonMovieCredit]) -> PersonProfile {
        PersonProfile(
            id: id,
            name: name,
            profilePath: profilePath,
            knownForDepartment: knownForDepartment,
            birthday: birthday,
            deathday: deathday,
            placeOfBirth: placeOfBirth,
            biography: biography ?? "",
            credits: credits
        )
    }
}

public struct PersonMovieCreditsDTO: Decodable, Sendable {
    public let cast: [PersonCreditDTO]

    private enum CodingKeys: String, CodingKey {
        case cast
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.cast = try container.decodeIfPresent([PersonCreditDTO].self, forKey: .cast) ?? []
    }
}

public struct PersonCreditDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let posterPath: String?
    public let releaseDate: String?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let character: String

    private enum CodingKeys: String, CodingKey {
        case id
        case title
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case character
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        self.posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.voteAverage = try container.decodeIfPresent(Double.self, forKey: .voteAverage)
        self.voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount)
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
    }

    public func toDomain() -> PersonMovieCredit {
        PersonMovieCredit(
            id: id,
            title: title,
            posterPath: posterPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage ?? 0.0,
            voteCount: voteCount ?? 0,
            character: character
        )
    }
}
