//
//  GetGenresUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetGenresUseCaseProtocol: Sendable {
    func execute() async throws -> [Genre]
}

public final class GetGenresUseCase: GetGenresUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute() async throws -> [Genre] {
        try await repository.getGenres()
    }
}
