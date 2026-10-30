//
//  MovieVideo.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieVideo: Identifiable, Equatable, Sendable {
    public let id: String
    public let key: String
    public let name: String
    public let site: String
    public let type: String
    public let official: Bool

    public init(
        id: String,
        key: String,
        name: String,
        site: String,
        type: String,
        official: Bool
    ) {
        self.id = id
        self.key = key
        self.name = name
        self.site = site
        self.type = type
        self.official = official
    }

    public static func best(from videos: [MovieVideo]) -> MovieVideo? {
        let youTubeVideos = videos.filter { $0.site == "YouTube" && !$0.key.isEmpty }

        if let officialTrailer = youTubeVideos.first(where: { $0.type == "Trailer" && $0.official }) {
            return officialTrailer
        }
        if let officialTeaser = youTubeVideos.first(where: { $0.type == "Teaser" && $0.official }) {
            return officialTeaser
        }
        return youTubeVideos.first
    }
}
