//
//  SearchMoviesUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
@testable import Mobile_Swift_Movie_MVVM

struct SearchMoviesUseCaseTests {

    @Test func testSearchReturnsMoviesForValidQuery() async throws {
        let repository = MockMovieRepository()
        let sample = [
            Movie(
                id: 99,
                title: "Avatar",
                overview: "A paraplegic Marine dispatched to the moon Pandora...",
                posterPath: "/avatar.jpg",
                backdropPath: nil,
                releaseDate: "2009-12-18",
                voteAverage: 7.9,
                voteCount: 30000
            )
        ]
        repository.searchResult = .success(sample)
        let useCase = SearchMoviesUseCase(repository: repository)

        let results = try await useCase.execute(query: "Avatar", page: 1)

        #expect(results.count == 1)
        #expect(results.first?.title == "Avatar")
    }

    @Test func testSearchReturnsEmptyArrayForEmptyOrWhitespaceQuery() async throws {
        let repository = MockMovieRepository()
        let useCase = SearchMoviesUseCase(repository: repository)

        let result1 = try await useCase.execute(query: "", page: 1)
        let result2 = try await useCase.execute(query: "   ", page: 1)

        #expect(result1.isEmpty)
        #expect(result2.isEmpty)
    }
}
