//
//  DiscoverMoviesUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct DiscoverMoviesUseCaseTests {

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

    @Test func testExecuteWithSingleGenreReturnsMovies() async throws {
        let repository = MockMovieRepository()
        let sampleMovies = [
            makeMovie(id: 1, title: "Die Hard"),
            makeMovie(id: 2, title: "Mad Max")
        ]
        repository.discoverResult = .success(sampleMovies)

        let useCase = DiscoverMoviesUseCase(repository: repository)
        let results = try await useCase.execute(filters: DiscoverFilters(genreIds: [28]), page: 1)

        #expect(results == sampleMovies)
        #expect(repository.requestedDiscoverFilters?.genreIds == [28])
        #expect(repository.requestedDiscoverFilters?.sort == .popularity)
        #expect(repository.requestedDiscoverPage == 1)
    }

    @Test func testExecuteWithNoGenresStillRequestsCatalogue() async throws {
        let repository = MockMovieRepository()
        let useCase = DiscoverMoviesUseCase(repository: repository)

        _ = try await useCase.execute(filters: DiscoverFilters(), page: 1)

        #expect(repository.requestedDiscoverFilters == DiscoverFilters())
        #expect(repository.requestedDiscoverPage == 1)
    }

    @Test func testExecuteWithNonPositiveGenreIdReturnsEmptyArrayWithoutCallingRepo() async throws {
        let repository = MockMovieRepository()
        let useCase = DiscoverMoviesUseCase(repository: repository)

        let results = try await useCase.execute(filters: DiscoverFilters(genreIds: [0]), page: 1)

        #expect(results.isEmpty)
        #expect(repository.requestedDiscoverFilters == nil)
    }

    @Test func testExecutePropagatesRepositoryError() async {
        struct NetworkError: Error, LocalizedError {
            var errorDescription: String? { "TMDB unreachable" }
        }

        let repository = MockMovieRepository()
        repository.discoverResult = .failure(NetworkError())

        let useCase = DiscoverMoviesUseCase(repository: repository)

        await #expect(throws: NetworkError.self) {
            _ = try await useCase.execute(filters: DiscoverFilters(genreIds: [28]), page: 1)
        }
    }
}
