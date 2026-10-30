//
//  GenreListDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct GenreListDTO: Decodable, Sendable {
    public let genres: [GenreDTO]
}
