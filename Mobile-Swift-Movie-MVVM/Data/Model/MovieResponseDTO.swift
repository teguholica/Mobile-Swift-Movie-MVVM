//
//  MovieResponseDTO.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public struct MovieResponseDTO: Decodable, Sendable {
    public let page: Int
    public let results: [MovieDTO]
    public let totalPages: Int?
    public let totalResults: Int?

    enum CodingKeys: String, CodingKey {
        case page
        case results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
