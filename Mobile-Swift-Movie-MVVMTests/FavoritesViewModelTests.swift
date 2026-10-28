//
//  FavoritesViewModelTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

@MainActor
struct FavoritesViewModelTests {

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 8.0,
            voteCount: 10
        )
    }

    @Test func testFetchFavoritesLoadsList() async {
        let repository = MockMovieRepository()
        let movie = makeMovie(id: 1, title: "Interstellar")
        repository.favoritesList = [movie]

        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let viewModel = FavoritesViewModel(
            getFavoriteMoviesUseCase: getUseCase,
            removeFavoriteMovieUseCase: removeUseCase
        )

        #expect(viewModel.favorites.isEmpty)
        await viewModel.fetchFavorites()

        #expect(viewModel.favorites.count == 1)
        #expect(viewModel.favorites.first?.title == "Interstellar")
        #expect(viewModel.visibleFavorites.count == 1)
    }

    @Test func testRemoveFavoriteDeletesFromList() async {
        let repository = MockMovieRepository()
        let movie1 = makeMovie(id: 1, title: "Movie 1")
        let movie2 = makeMovie(id: 2, title: "Movie 2")
        repository.favoritesList = [movie1, movie2]

        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let viewModel = FavoritesViewModel(
            getFavoriteMoviesUseCase: getUseCase,
            removeFavoriteMovieUseCase: removeUseCase
        )

        await viewModel.fetchFavorites()
        #expect(viewModel.favorites.count == 2)

        await viewModel.removeFavorite(movie: movie1)

        #expect(viewModel.favorites.count == 1)
        #expect(viewModel.favorites.first?.id == 2)
    }

    @Test func testStageRemovalSoftHidesMovieAndShowsToast() async {
        let repository = MockMovieRepository()
        let movie = makeMovie(id: 42, title: "Oppenheimer")
        repository.favoritesList = [movie]

        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let viewModel = FavoritesViewModel(
            getFavoriteMoviesUseCase: getUseCase,
            removeFavoriteMovieUseCase: removeUseCase
        )

        await viewModel.fetchFavorites()
        #expect(viewModel.visibleFavorites.count == 1)

        viewModel.stageRemoval(movie: movie, delayDuration: .seconds(10))

        // Immediately soft-hidden
        #expect(viewModel.softHiddenMovieIds.contains(42))
        #expect(viewModel.visibleFavorites.isEmpty)
        #expect(viewModel.toastMovie?.id == 42)
        // Not yet deleted from repository!
        #expect(repository.favoritesList.count == 1)
    }

    @Test func testUndoRemovalRestoresMovieWithoutDatabaseCall() async {
        let repository = MockMovieRepository()
        let movie = makeMovie(id: 42, title: "Oppenheimer")
        repository.favoritesList = [movie]

        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let viewModel = FavoritesViewModel(
            getFavoriteMoviesUseCase: getUseCase,
            removeFavoriteMovieUseCase: removeUseCase
        )

        await viewModel.fetchFavorites()
        viewModel.stageRemoval(movie: movie, delayDuration: .seconds(10))
        #expect(viewModel.visibleFavorites.isEmpty)

        // Undo
        viewModel.undoRemoval()

        #expect(viewModel.softHiddenMovieIds.isEmpty)
        #expect(viewModel.visibleFavorites.count == 1)
        #expect(viewModel.visibleFavorites.first?.id == 42)
        #expect(viewModel.toastMovie == nil)
        #expect(repository.favoritesList.count == 1)
    }

    @Test func testStageRemovalAutoCommitsAfterDelay() async throws {
        let repository = MockMovieRepository()
        let movie = makeMovie(id: 42, title: "Oppenheimer")
        repository.favoritesList = [movie]

        let getUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let removeUseCase = RemoveFavoriteMovieUseCase(repository: repository)
        let viewModel = FavoritesViewModel(
            getFavoriteMoviesUseCase: getUseCase,
            removeFavoriteMovieUseCase: removeUseCase
        )

        await viewModel.fetchFavorites()
        // Delay of 50ms for swift testing
        viewModel.stageRemoval(movie: movie, delayDuration: .milliseconds(50))

        try await Task.sleep(for: .milliseconds(120))

        // Committed after delay
        #expect(viewModel.favorites.isEmpty)
        #expect(viewModel.visibleFavorites.isEmpty)
        #expect(viewModel.toastMovie == nil)
        #expect(repository.favoritesList.isEmpty)
    }
}
