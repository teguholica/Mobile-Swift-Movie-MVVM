//
//  MovieCreditsDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieCreditsResponseDTO: Decodable, Sendable {
    public let cast: [CastMemberDTO]
}

public struct CastMemberDTO: Decodable, Sendable {
    public let id: Int
    public let name: String
    public let character: String
    public let profilePath: String?
    public let order: Int

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case character
        case profilePath = "profile_path"
        case order
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        self.character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        self.profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? Int.max
    }

    public func toDomain() -> CastMember {
        CastMember(
            id: id,
            name: name,
            character: character,
            profilePath: profilePath
        )
    }
}
