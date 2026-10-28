//
//  MovieDetail.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieDetail: Identifiable, Equatable, Sendable {
    public let id: Int
    public let title: String
    public let overview: String
    public let posterPath: String?
    public let backdropPath: String?
    public let releaseDate: String?
    public let voteAverage: Double
    public let voteCount: Int
    public let runtime: Int?
    public let tagline: String?
    public let status: String?
    public let genres: [Genre]

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        voteCount: Int,
        runtime: Int?,
        tagline: String?,
        status: String?,
        genres: [Genre]
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.runtime = runtime
        self.tagline = tagline
        self.status = status
        self.genres = genres
    }

    public var formattedRuntime: String {
        guard let runtime = runtime, runtime > 0 else { return "N/A" }
        let hours = runtime / 60
        let minutes = runtime % 60
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }

    public var formattedReleaseYear: String {
        guard let releaseDate = releaseDate, releaseDate.count >= 4 else { return "N/A" }
        return String(releaseDate.prefix(4))
    }
}
