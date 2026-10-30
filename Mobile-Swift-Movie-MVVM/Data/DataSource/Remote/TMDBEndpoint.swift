//
//  TMDBEndpoint.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public enum TMDBEndpoint {
    case nowPlaying(page: Int)
    case popular(page: Int)
    case topRated(page: Int)
    case search(query: String, year: Int?, page: Int)
    case discover(filters: DiscoverFilters, page: Int)
    case genres
    case detail(id: Int)
    case person(id: Int)

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
        case .genres:
            return "/genre/movie/list"
        case .detail(let id):
            return "/movie/\(id)"
        case .person(let id):
            return "/person/\(id)"
        }
    }

    var queryItems: [URLQueryItem] {
        switch self {
        case .nowPlaying(let page), .popular(let page), .topRated(let page):
            return [URLQueryItem(name: "page", value: "\(page)")]
        case .search(let query, let year, let page):
            var items = [
                URLQueryItem(name: "query", value: query),
                URLQueryItem(name: "page", value: "\(page)")
            ]
            if let year {
                items.append(URLQueryItem(name: "year", value: "\(year)"))
            }
            return items
        case .discover(let filters, let page):
            var items = [
                URLQueryItem(name: "page", value: "\(page)"),
                URLQueryItem(name: "sort_by", value: filters.sort.tmdbSortValue)
            ]

            if !filters.genreIds.isEmpty {
                let value = filters.genreIds.map(String.init).joined(separator: "|")
                items.append(URLQueryItem(name: "with_genres", value: value))
            }

            if let yearRange = filters.yearRange {
                items.append(URLQueryItem(name: "primary_release_date.gte", value: "\(yearRange.lowerBound)-01-01"))
                items.append(URLQueryItem(name: "primary_release_date.lte", value: "\(yearRange.upperBound)-12-31"))
            }

            if let minRating = filters.minRating {
                items.append(URLQueryItem(name: "vote_average.gte", value: String(minRating)))
            }

            if filters.minRating != nil || filters.sort == .rating {
                items.append(URLQueryItem(name: "vote_count.gte", value: "50"))
            }

            return items
        case .genres:
            return []
        case .detail:
            return [
                URLQueryItem(name: "append_to_response", value: "videos,credits,watch/providers,recommendations,similar")
            ]
        case .person:
            return [
                URLQueryItem(name: "append_to_response", value: "movie_credits")
            ]
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

private extension DiscoverSort {
    var tmdbSortValue: String {
        switch self {
        case .popularity:
            return "popularity.desc"
        case .rating:
            return "vote_average.desc"
        case .newest:
            return "primary_release_date.desc"
        case .title:
            return "title.asc"
        }
    }
}
