//
//  GetNowPlayingMoviesUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
@testable import Mobile_Swift_Movie_MVVM

struct GetNowPlayingMoviesUseCaseTests {

    @Test func testExecuteReturnsMoviesOnSuccess() async throws {
        let mockRepository = MockMovieRepository()
        let sampleMovies = [
            Movie(
                id: 101,
                title: "Sonic the Hedgehog 3",
                overview: "Sonic, Knuckles, and Tails reunite against a powerful new adversary.",
                posterPath: "/sonic.jpg",
                backdropPath: "/sonic_backdrop.jpg",
                releaseDate: "2024-12-20",
                voteAverage: 8.0,
                voteCount: 1200
            )
        ]
        mockRepository.nowPlayingResult = .success(sampleMovies)
        let useCase = GetNowPlayingMoviesUseCase(repository: mockRepository)

        let result = try await useCase.execute(page: 1)

        #expect(result.count == 1)
        #expect(result.first?.id == 101)
        #expect(result.first?.title == "Sonic the Hedgehog 3")
        #expect(mockRepository.getNowPlayingCallCount == 1)
        #expect(mockRepository.requestedNowPlayingPage == 1)
    }

    @Test func testExecutePropagatesErrorOnFailure() async throws {
        struct TestError: Error, Equatable {}
        let mockRepository = MockMovieRepository()
        mockRepository.nowPlayingResult = .failure(TestError())
        let useCase = GetNowPlayingMoviesUseCase(repository: mockRepository)

        await #expect(throws: TestError.self) {
            _ = try await useCase.execute(page: 1)
        }
    }
}
