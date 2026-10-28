//
//  GetPopularMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetPopularMoviesUseCaseProtocol: Sendable {
    func execute(page: Int) async throws -> [Movie]
}

public final class GetPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(page: Int = 1) async throws -> [Movie] {
        try await repository.getPopularMovies(page: page)
    }
}
