//
//  GenreDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct GenreDTO: Decodable, Sendable {
    public let id: Int
    public let name: String

    public func toDomain() -> Genre {
        Genre(id: id, name: name)
    }
}
