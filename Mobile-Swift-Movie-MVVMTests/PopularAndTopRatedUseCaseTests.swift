//
//  PopularAndTopRatedUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
@testable import Mobile_Swift_Movie_MVVM

struct PopularAndTopRatedUseCaseTests {

    @Test func testGetPopularMoviesUseCaseReturnsMovies() async throws {
        let repository = MockMovieRepository()
        let sample = [
            Movie(
                id: 1,
                title: "Popular Movie",
                overview: "Popular overview",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2024-01-01",
                voteAverage: 7.9,
                voteCount: 500
            )
        ]
        repository.popularResult = .success(sample)
        let useCase = GetPopularMoviesUseCase(repository: repository)

        let result = try await useCase.execute(page: 2)

        #expect(result.count == 1)
        #expect(result.first?.title == "Popular Movie")
        #expect(repository.getPopularCallCount == 1)
        #expect(repository.requestedPopularPages == [2])
    }

    @Test func testGetTopRatedMoviesUseCaseReturnsMovies() async throws {
        let repository = MockMovieRepository()
        let sample = [
            Movie(
                id: 2,
                title: "Top Rated Movie",
                overview: "Top rated overview",
                posterPath: nil,
                backdropPath: nil,
                releaseDate: "2023-01-01",
                voteAverage: 9.1,
                voteCount: 2000
            )
        ]
        repository.topRatedResult = .success(sample)
        let useCase = GetTopRatedMoviesUseCase(repository: repository)

        let result = try await useCase.execute(page: 1)

        #expect(result.count == 1)
        #expect(result.first?.title == "Top Rated Movie")
        #expect(result.first?.voteAverage == 9.1)
    }
}
