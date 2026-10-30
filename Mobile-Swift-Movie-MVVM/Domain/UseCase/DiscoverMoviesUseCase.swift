//
//  DiscoverMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol DiscoverMoviesUseCaseProtocol: Sendable {
    func execute(filters: DiscoverFilters, page: Int) async throws -> [Movie]
}

public final class DiscoverMoviesUseCase: DiscoverMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(filters: DiscoverFilters, page: Int = 1) async throws -> [Movie] {
        guard filters.genreIds.allSatisfy({ $0 > 0 }) else { return [] }
        return try await repository.discoverMovies(filters: filters, page: page)
    }
}
