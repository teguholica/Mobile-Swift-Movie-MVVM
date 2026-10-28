//
//  GetNowPlayingMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetNowPlayingMoviesUseCaseProtocol: Sendable {
    func execute(page: Int) async throws -> [Movie]
}

public final class GetNowPlayingMoviesUseCase: GetNowPlayingMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(page: Int = 1) async throws -> [Movie] {
        try await repository.getNowPlayingMovies(page: page)
    }
}
