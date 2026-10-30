//
//  GetGenresUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct GetGenresUseCaseTests {

    @Test func testExecuteReturnsRepositoryGenres() async throws {
        let repository = MockMovieRepository()
        let genres = [Genre(id: 28, name: "Action"), Genre(id: 37, name: "Western")]
        repository.genresResult = .success(genres)

        let useCase = GetGenresUseCase(repository: repository)
        let results = try await useCase.execute()

        #expect(results == genres)
        #expect(repository.getGenresCallCount == 1)
    }

    @Test func testExecutePropagatesRepositoryError() async {
        struct CatalogueError: Error, LocalizedError {
            var errorDescription: String? { "Genre catalogue unavailable" }
        }

        let repository = MockMovieRepository()
        repository.genresResult = .failure(CatalogueError())

        let useCase = GetGenresUseCase(repository: repository)

        await #expect(throws: CatalogueError.self) {
            _ = try await useCase.execute()
        }
    }
}
