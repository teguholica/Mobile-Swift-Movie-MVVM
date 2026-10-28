//
//  FavoritesUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
@testable import Mobile_Swift_Movie_MVVM

struct FavoritesUseCaseTests {

    private func makeMovie(id: Int = 1) -> Movie {
        Movie(
            id: id,
            title: "Favorite Movie \(id)",
            overview: "Overview",
            posterPath: "/poster.jpg",
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 8.5,
            voteCount: 100
        )
    }

    @Test func testToggleFavoriteAddsAndRemovesMovie() async throws {
        let repository = MockMovieRepository()
        let toggleUseCase = ToggleFavoriteMovieUseCase(repository: repository)
        let checkUseCase = CheckIsFavoriteUseCase(repository: repository)
        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let movie = makeMovie(id: 42)

        // Initial
        let isFavInitial = try await checkUseCase.execute(movieId: 42)
        #expect(isFavInitial == false)

        // Toggle ON
        let added = try await toggleUseCase.execute(movie: movie)
        #expect(added == true)

        let isFavAfterAdd = try await checkUseCase.execute(movieId: 42)
        #expect(isFavAfterAdd == true)

        let list = try await getUseCase.execute()
        #expect(list.count == 1)
        #expect(list.first?.id == 42)

        // Toggle OFF
        let removed = try await toggleUseCase.execute(movie: movie)
        #expect(removed == false)

        let isFavAfterRemove = try await checkUseCase.execute(movieId: 42)
        #expect(isFavAfterRemove == false)
    }

    @Test func testRemoveFavoriteMovie() async throws {
        let repository = MockMovieRepository()
        let toggleUseCase = ToggleFavoriteMovieUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)

        let movie = makeMovie(id: 77)
        _ = try await toggleUseCase.execute(movie: movie)
        #expect(try await getUseCase.execute().count == 1)

        try await removeUseCase.execute(movieId: 77)
        #expect(try await getUseCase.execute().isEmpty)
    }
}
