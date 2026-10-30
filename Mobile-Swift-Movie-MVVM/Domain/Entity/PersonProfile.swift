//
//  PersonProfile.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct PersonProfile: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let profilePath: String?
    public let knownForDepartment: String?
    public let birthday: String?
    public let deathday: String?
    public let placeOfBirth: String?
    public let biography: String
    public let credits: [PersonMovieCredit]

    public init(
        id: Int,
        name: String,
        profilePath: String?,
        knownForDepartment: String?,
        birthday: String? = nil,
        deathday: String? = nil,
        placeOfBirth: String? = nil,
        biography: String = "",
        credits: [PersonMovieCredit]
    ) {
        self.id = id
        self.name = name
        self.profilePath = profilePath
        self.knownForDepartment = knownForDepartment
        self.birthday = birthday
        self.deathday = deathday
        self.placeOfBirth = placeOfBirth
        self.biography = biography
        self.credits = credits
    }
}

public struct PersonMovieCredit: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let posterPath: String?
    public let releaseDate: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let character: String

    public init(
        id: Int,
        title: String,
        posterPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        voteCount: Int,
        character: String
    ) {
        self.id = id
        self.title = title
        self.posterPath = posterPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.character = character
    }

    public var releaseYear: String? {
        guard let releaseDate, releaseDate.count >= 4 else { return nil }
        return String(releaseDate.prefix(4))
    }
}
