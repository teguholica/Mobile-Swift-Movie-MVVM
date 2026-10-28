//
//  MovieDetailDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieDetailDTO: Decodable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String?
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double?
    public let voteCount: Int?
    public let runtime: Int?
    public let tagline: String?
    public let status: String?
    public let genres: [GenreDTO]?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case overview
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case releaseDate = "release_date"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case runtime
        case tagline
        case status
        case genres
    }

    public func toDomain() -> MovieDetail {
        MovieDetail(
            id: id,
            title: title,
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage ?? 0.0,
            voteCount: voteCount ?? 0,
            runtime: runtime,
            tagline: tagline,
            status: status,
            genres: (genres ?? []).map { $0.toDomain() }
        )
    }
}
