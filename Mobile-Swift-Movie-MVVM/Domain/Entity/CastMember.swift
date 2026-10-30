//
//  CastMember.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct CastMember: Identifiable, Equatable, Sendable {
    public let id: Int
    public let name: String
    public let character: String
    public let profilePath: String?

    public init(
        id: Int,
        name: String,
        character: String,
        profilePath: String?
    ) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
    }

    public var uniqueID: String {
        "\(id)-\(character)"
    }
}
