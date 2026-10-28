//
//  GetTopRatedMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetTopRatedMoviesUseCaseProtocol: Sendable {
    func execute(page: Int) async throws -> [Movie]
}

public final class GetTopRatedMoviesUseCase: GetTopRatedMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(page: Int = 1) async throws -> [Movie] {
        try await repository.getTopRatedMovies(page: page)
    }
}
