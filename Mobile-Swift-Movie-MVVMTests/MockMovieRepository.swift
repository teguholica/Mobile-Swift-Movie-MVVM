//
//  MockMovieRepository.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Foundation
@testable import Mobile_Swift_Movie_MVVM

final class MockMovieRepository: MovieRepositoryProtocol, @unchecked Sendable {
    var nowPlayingResult: Result<[Movie], Error> = .success([])
    var popularResult: Result<[Movie], Error> = .success([])
    var topRatedResult: Result<[Movie], Error> = .success([])
    var searchResult: Result<[Movie], Error> = .success([])
    var discoverResult: Result<[Movie], Error> = .success([])
    var movieDetailsResult: Result<MovieDetail, Error> = .failure(URLError(.badURL))
    var getMovieDetailsCallCount = 0
    var requestedMovieDetailId: Int?
    var requestedDiscoverGenreId: Int?
    var requestedDiscoverPage: Int?

    var favoritesList: [Movie] = []
    var toggleFavoriteResult: Bool = true
    var isFavoriteResult: Bool = false

    var getNowPlayingCallCount = 0
    var requestedNowPlayingPage: Int?
    var getPopularCallCount = 0
    var requestedPopularPages: [Int] = []
    var popularResultProvider: ((Int) -> Result<[Movie], Error>)?
    var discoverResultProvider: ((Int) -> Result<[Movie], Error>)?

    func getNowPlayingMovies(page: Int) async throws -> [Movie] {
        getNowPlayingCallCount += 1
        requestedNowPlayingPage = page
        return try nowPlayingResult.get()
    }

    func getPopularMovies(page: Int) async throws -> [Movie] {
        getPopularCallCount += 1
        requestedPopularPages.append(page)
        if let provider = popularResultProvider {
            return try provider(page).get()
        }
        return try popularResult.get()
    }

    func getTopRatedMovies(page: Int) async throws -> [Movie] {
        return try topRatedResult.get()
    }

    func searchMovies(query: String, page: Int) async throws -> [Movie] {
        return try searchResult.get()
    }

    func discoverMovies(genreId: Int, page: Int) async throws -> [Movie] {
        requestedDiscoverGenreId = genreId
        requestedDiscoverPage = page
        if let provider = discoverResultProvider {
            return try provider(genreId).get()
        }
        return try discoverResult.get()
    }

    func getMovieDetails(id: Int) async throws -> MovieDetail {
        getMovieDetailsCallCount += 1
        requestedMovieDetailId = id
        return try movieDetailsResult.get()
    }

    func getFavoriteMovies() async throws -> [Movie] {
        return favoritesList
    }

    func toggleFavorite(movie: Movie) async throws -> Bool {
        if favoritesList.contains(where: { $0.id == movie.id }) {
            favoritesList.removeAll { $0.id == movie.id }
            return false
        } else {
            favoritesList.append(movie)
            return true
        }
    }

    func isFavorite(movieId: Int) async throws -> Bool {
        return favoritesList.contains(where: { $0.id == movieId }) || isFavoriteResult
    }

    func removeFavorite(movieId: Int) async throws {
        favoritesList.removeAll { $0.id == movieId }
    }
}
