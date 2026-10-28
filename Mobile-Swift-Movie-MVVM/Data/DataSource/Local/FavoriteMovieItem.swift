//
//  FavoriteMovieItem.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import SwiftData

@Model
public final class FavoriteMovieItem {
    @Attribute(.unique) public var id: Int
    public var title: String
    public var overview: String
    public var posterPath: String?
    public var backdropPath: String?
    public var releaseDate: String?
    public var voteAverage: Double
    public var voteCount: Int
    public var addedAt: Date

    public init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        releaseDate: String?,
        voteAverage: Double,
        voteCount: Int,
        addedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.releaseDate = releaseDate
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.addedAt = addedAt
    }

    public func toDomain() -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage,
            voteCount: voteCount
        )
    }
}
