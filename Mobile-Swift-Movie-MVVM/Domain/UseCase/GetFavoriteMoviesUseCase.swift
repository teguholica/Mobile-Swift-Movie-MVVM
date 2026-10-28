//
//  GetFavoriteMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetFavoriteMoviesUseCaseProtocol: Sendable {
    func execute() async throws -> [Movie]
}

public final class GetFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Movie] {
        try await repository.getFavoriteMovies()
    }
}
