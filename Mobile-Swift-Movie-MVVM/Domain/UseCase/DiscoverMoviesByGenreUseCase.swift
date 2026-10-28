//
//  DiscoverMoviesByGenreUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol DiscoverMoviesByGenreUseCaseProtocol: Sendable {
    func execute(genreId: Int, page: Int) async throws -> [Movie]
}

public final class DiscoverMoviesByGenreUseCase: DiscoverMoviesByGenreUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(genreId: Int, page: Int = 1) async throws -> [Movie] {
        guard genreId > 0 else { return [] }
        return try await repository.discoverMovies(genreId: genreId, page: page)
    }
}
