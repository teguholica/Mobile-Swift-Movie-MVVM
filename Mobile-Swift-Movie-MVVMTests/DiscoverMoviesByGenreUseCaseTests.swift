//
//  DiscoverMoviesByGenreUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct DiscoverMoviesByGenreUseCaseTests {

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview for \(title)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: "2024-01-01",
            voteAverage: 8.0,
            voteCount: 150
        )
    }

    @Test func testExecuteWithValidGenreIdReturnsMovies() async throws {
        let repository = MockMovieRepository()
        let sampleMovies = [
            makeMovie(id: 1, title: "Die Hard"),
            makeMovie(id: 2, title: "Mad Max")
        ]
        repository.discoverResult = .success(sampleMovies)

        let useCase = DiscoverMoviesByGenreUseCase(repository: repository)
        let results = try await useCase.execute(genreId: 28, page: 1)

        #expect(results == sampleMovies)
        #expect(repository.requestedDiscoverGenreId == 28)
        #expect(repository.requestedDiscoverPage == 1)
    }

    @Test func testExecuteWithZeroOrNegativeGenreIdReturnsEmptyArrayWithoutCallingRepo() async throws {
        let repository = MockMovieRepository()
        let useCase = DiscoverMoviesByGenreUseCase(repository: repository)

        let results = try await useCase.execute(genreId: 0, page: 1)
        #expect(results.isEmpty)
        #expect(repository.requestedDiscoverGenreId == nil)
    }

    @Test func testExecutePropagatesRepositoryError() async {
        struct NetworkError: Error, LocalizedError {
            var errorDescription: String? { "TMDB unreachable" }
        }

        let repository = MockMovieRepository()
        repository.discoverResult = .failure(NetworkError())

        let useCase = DiscoverMoviesByGenreUseCase(repository: repository)

        await #expect(throws: NetworkError.self) {
            _ = try await useCase.execute(genreId: 28, page: 1)
        }
    }
}
