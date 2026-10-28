//
//  CheckIsFavoriteUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol CheckIsFavoriteUseCaseProtocol: Sendable {
    func execute(movieId: Int) async throws -> Bool
}

public final class CheckIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(movieId: Int) async throws -> Bool {
        try await repository.isFavorite(movieId: movieId)
    }
}
