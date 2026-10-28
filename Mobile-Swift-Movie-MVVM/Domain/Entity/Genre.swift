//
//  Genre.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct Genre: Identifiable, Equatable, Hashable, Sendable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }
}

public extension Genre {
    static let popularPresets: [Genre] = [
        Genre(id: 28, name: "Action"),
        Genre(id: 12, name: "Adventure"),
        Genre(id: 16, name: "Animation"),
        Genre(id: 35, name: "Comedy"),
        Genre(id: 18, name: "Drama"),
        Genre(id: 27, name: "Horror"),
        Genre(id: 878, name: "Sci-Fi"),
        Genre(id: 53, name: "Thriller")
    ]
}
