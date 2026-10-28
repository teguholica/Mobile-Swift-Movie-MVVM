//
//  ToggleFavoriteMovieUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol ToggleFavoriteMovieUseCaseProtocol: Sendable {
    func execute(movie: Movie) async throws -> Bool
}

public final class ToggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(movie: Movie) async throws -> Bool {
        try await repository.toggleFavorite(movie: movie)
    }
}
