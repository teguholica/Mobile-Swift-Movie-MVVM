//
//  GetPersonProfileUseCase.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public protocol GetPersonProfileUseCaseProtocol: Sendable {
    func execute(id: Int) async throws -> PersonProfile
}

public final class GetPersonProfileUseCase: GetPersonProfileUseCaseProtocol {
    private let repository: MovieRepositoryProtocol

    public init(repository: MovieRepositoryProtocol) {
        self.repository = repository
    }

    public func execute(id: Int) async throws -> PersonProfile {
        try await repository.getPersonProfile(id: id)
    }
}
