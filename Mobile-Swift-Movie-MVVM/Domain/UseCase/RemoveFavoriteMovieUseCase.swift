//
//  RemoveFavoriteMovieUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol RemoveFavoriteMovieUseCaseProtocol: Sendable {
    func execute(movieId: Int) async throws
}

public final class RemoveFavoriteMovieUseCase: RemoveFavoriteMovieUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(movieId: Int) async throws {
        try await repository.removeFavorite(movieId: movieId)
    }
}
