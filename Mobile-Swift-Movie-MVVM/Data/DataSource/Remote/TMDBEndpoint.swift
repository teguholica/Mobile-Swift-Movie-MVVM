//
//  TMDBEndpoint.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum TMDBEndpoint {
    case nowPlaying(page: Int)
    case popular(page: Int)
    case topRated(page: Int)
    case search(query: String, page: Int)
    case discover(genreId: Int, page: Int)
    case detail(id: Int)

    var path: String {
        switch self {
        case .nowPlaying:
            return "/movie/now_playing"
        case .popular:
            return "/movie/popular"
        case .topRated:
            return "/movie/top_rated"
        case .search:
            return "/search/movie"
        case .discover:
            return "/discover/movie"
        case .detail(let id):
            return "/movie/\(id)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .nowPlaying(let page), .popular(let page), .topRated(let page):
            return [URLQueryItem(name: "page", value: "\(page)")]
        case .search(let query, let page):
            return [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        case .discover(let genreId, let page):
            return [
                URLQueryItem(name: "with_genres", value: "\(genreId)"),
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: "popularity.desc")
            ]
        case .detail:
            return []
        }
    }

    public func makeURLRequest() throws -> URLRequest {
        guard var components = URLComponents(string: TMDBConfig.baseURL + path) else {
            throw URLError(.badURL)
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(TMDBConfig.apiReadAccessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        return request
    }
}
