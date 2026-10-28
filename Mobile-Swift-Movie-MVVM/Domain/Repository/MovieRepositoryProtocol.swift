//
//  MovieRepositoryProtocol.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol MovieRepositoryProtocol: Sendable {
    func getNowPlayingMovies(page: Int) async throws -> [Movie]
    func getPopularMovies(page: Int) async throws -> [Movie]
    func getTopRatedMovies(page: Int) async throws -> [Movie]
    func searchMovies(query: String, page: Int) async throws -> [Movie]
    func discoverMovies(genreId: Int, page: Int) async throws -> [Movie]
    func getMovieDetails(id: Int) async throws -> MovieDetail

    func getFavoriteMovies() async throws -> [Movie]
    func toggleFavorite(movie: Movie) async throws -> Bool
    func isFavorite(movieId: Int) async throws -> Bool
    func removeFavorite(movieId: Int) async throws
}
