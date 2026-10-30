//
//  SearchMoviesUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol SearchMoviesUseCaseProtocol: Sendable {
    func execute(query: String, year: Int?, page: Int) async throws -> [Movie]
}

public final class SearchMoviesUseCase: SearchMoviesUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(query: String, year: Int? = nil, page: Int = 1) async throws -> [Movie] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return try await repository.searchMovies(query: trimmed, year: year, page: page)
    }
}
