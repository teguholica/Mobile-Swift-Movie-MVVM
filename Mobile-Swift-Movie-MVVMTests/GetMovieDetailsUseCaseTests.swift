//
//  GetMovieDetailsUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
@testable import Mobile_Swift_Movie_MVVM

struct GetMovieDetailsUseCaseTests {

    @Test func testExecuteReturnsMovieDetailOnSuccess() async throws {
        let repository = MockMovieRepository()
        let sampleDetail = MovieDetail(
            id: 550,
            title: "Fight Club",
            overview: "An insomniac office worker...",
            posterPath: "/poster.jpg",
            backdropPath: "/backdrop.jpg",
            releaseDate: "1999-10-15",
            voteAverage: 8.4,
            voteCount: 26000,
            runtime: 139,
            tagline: "Mischief. Mayhem. Soap.",
            status: "Released",
            genres: [Genre(id: 18, name: "Drama")]
        )
        repository.movieDetailsResult = .success(sampleDetail)
        let useCase = GetMovieDetailsUseCase(repository: repository)

        let result = try await useCase.execute(id: 550)

        #expect(result.id == 550)
        #expect(result.title == "Fight Club")
        #expect(result.formattedRuntime == "2h 19m")
        #expect(result.formattedReleaseYear == "1999")
        #expect(result.genres.count == 1)
        #expect(repository.getMovieDetailsCallCount == 1)
        #expect(repository.requestedMovieDetailId == 550)
    }

    @Test func testExecutePropagatesErrorOnFailure() async throws {
        struct DetailError: Error, Equatable {}
        let repository = MockMovieRepository()
        repository.movieDetailsResult = .failure(DetailError())
        let useCase = GetMovieDetailsUseCase(repository: repository)

        await #expect(throws: DetailError.self) {
            _ = try await useCase.execute(id: 999)
        }
    }
}
