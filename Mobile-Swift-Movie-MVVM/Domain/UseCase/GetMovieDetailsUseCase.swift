//
//  GetMovieDetailsUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetMovieDetailsUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> MovieDetail
}

public final class GetMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> MovieDetail {
        try await repository.getMovieDetails(id: id)
    }
}
