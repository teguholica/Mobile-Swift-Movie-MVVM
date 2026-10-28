//
//  MovieRepositoryImpl.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public final class MovieRepositoryImpl: MovieRepositoryProtocol {
    private let networkService: TMDBNetworkServiceProtocol
    private let localDataSource: SwiftDataFavoriteDataSourceProtocol

    public init(
        networkService: TMDBNetworkServiceProtocol = TMDBNetworkService(),
        localDataSource: SwiftDataFavoriteDataSourceProtocol = SwiftDataFavoriteDataSource.createDefault()
    ) {
        self.networkService = networkService
        self.localDataSource = localDataSource
    }

    public func getNowPlayingMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.nowPlaying(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getPopularMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.popular(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getTopRatedMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.topRated(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func searchMovies(query: String, page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.search(query: query, page: page))
        return response.results.map { $0.toDomain() }
    }

    public func discoverMovies(genreId: Int, page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.discover(genreId: genreId, page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getMovieDetails(id: Int) async throws -> MovieDetail {
        let response: MovieDetailDTO = try await networkService.request(.detail(id: id))
        return response.toDomain()
    }

    public func getFavoriteMovies() async throws -> [Movie] {
        try await localDataSource.getFavorites()
    }

    public func toggleFavorite(movie: Movie) async throws -> Bool {
        try await localDataSource.toggleFavorite(movie: movie)
    }

    public func isFavorite(movieId: Int) async throws -> Bool {
        try await localDataSource.isFavorite(movieId: movieId)
    }

    public func removeFavorite(movieId: Int) async throws {
        try await localDataSource.removeFavorite(movieId: movieId)
    }
}
