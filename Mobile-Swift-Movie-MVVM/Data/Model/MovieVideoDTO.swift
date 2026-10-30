//
//  MovieVideoDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieVideosResponseDTO: Decodable, Sendable {
    public let results: [MovieVideoDTO]
}

public struct MovieVideoDTO: Decodable, Sendable {
    public let id: String
    public let key: String
    public let name: String
    public let site: String
    public let type: String
    public let official: Bool

    private enum CodingKeys: String, CodingKey {
        case id
        case key
        case name
        case site
        case type
        case official
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = try container.decodeIfPresent(String.self, forKey: .key) ?? ""
        self.key = key
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? key
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.site = try container.decodeIfPresent(String.self, forKey: .site) ?? ""
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        self.official = try container.decodeIfPresent(Bool.self, forKey: .official) ?? false
    }

    public func toDomain() -> MovieVideo {
        MovieVideo(
            id: id,
            key: key,
            name: name,
            site: site,
            type: type,
            official: official
        )
    }
}
