//
//  HomeViewModelTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct HomeViewModelTests {

    private func makeSUT(repository: MockMovieRepository = MockMovieRepository()) -> (HomeViewModel, MockMovieRepository) {
        let nowPlayingUseCase = GetNowPlayingMoviesUseCase(repository: repository)
        let popularUseCase = GetPopularMoviesUseCase(repository: repository)
        let topRatedUseCase = GetTopRatedMoviesUseCase(repository: repository)
        let toggleFavoriteUseCase = ToggleFavoriteMovieUseCase(repository: repository)
        let getFavoritesUseCase = GetFavoriteMoviesUseCase(repository: repository)
        let viewModel = HomeViewModel(
            getNowPlayingMoviesUseCase: nowPlayingUseCase,
            getPopularMoviesUseCase: popularUseCase,
            getTopRatedMoviesUseCase: topRatedUseCase,
            toggleFavoriteMovieUseCase: toggleFavoriteUseCase,
            getFavoriteMoviesUseCase: getFavoritesUseCase
        )
        return (viewModel, repository)
    }

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview for \(title)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: "2024-01-01",
            voteAverage: 7.5,
            voteCount: 100
        )
    }

    @Test func testInitialStateIsIdle() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.state == .idle)
        #expect(viewModel.nowPlayingMovies.isEmpty)
        #expect(viewModel.popularMovies.isEmpty)
        #expect(viewModel.topRatedMovies.isEmpty)
        #expect(viewModel.popularPage == 1)
        #expect(viewModel.canLoadMorePopular == true)
    }

    @Test func testFetchHomeDataSuccessUpdatesStateToLoaded() async {
        let (viewModel, repository) = makeSUT()
        let nowPlaying = [makeMovie(id: 1, title: "Now Playing 1")]
        let popular = [makeMovie(id: 2, title: "Popular 1")]
        let topRated = [makeMovie(id: 3, title: "Top Rated 1")]

        repository.nowPlayingResult = .success(nowPlaying)
        repository.popularResult = .success(popular)
        repository.topRatedResult = .success(topRated)

        await viewModel.fetchHomeData()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.nowPlayingMovies.count == 1)
        #expect(viewModel.popularMovies.count == 1)
        #expect(viewModel.topRatedMovies.count == 1)
        #expect(viewModel.popularMovies.first?.title == "Popular 1")
    }

    @Test func testFetchHomeDataFailureUpdatesStateToError() async {
        struct NetworkFailure: Error, LocalizedError {
            var errorDescription: String? { "Connection lost" }
        }

        let (viewModel, repository) = makeSUT()
        repository.nowPlayingResult = .failure(NetworkFailure())

        await viewModel.fetchHomeData()

        #expect(viewModel.state == .error("Connection lost"))
        #expect(viewModel.nowPlayingMovies.isEmpty)
    }

    @Test func testLoadMorePopularAppendsDeduplicatedMovies() async {
        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 10, title: "Movie 10"), makeMovie(id: 11, title: "Movie 11")]
        // page 2 includes movie 11 again (duplicate) and movie 12 (new)
        let page2 = [makeMovie(id: 11, title: "Movie 11 Duplicate"), makeMovie(id: 12, title: "Movie 12")]

        repository.nowPlayingResult = .success([])
        repository.popularResult = .success(page1)
        repository.topRatedResult = .success([])

        repository.popularResultProvider = { page in
            if page == 1 { return .success(page1) }
            if page == 2 { return .success(page2) }
            return .success([])
        }

        await viewModel.fetchHomeData()
        #expect(viewModel.popularMovies.count == 2)
        #expect(viewModel.popularPage == 1)

        await viewModel.loadMorePopularMovies()

        #expect(viewModel.popularPage == 2)
        #expect(viewModel.popularMovies.count == 3) // 10, 11, and 12 (no duplicate 11)
        #expect(viewModel.popularMovies.map { $0.id } == [10, 11, 12])
        #expect(viewModel.canLoadMorePopular == true)
        #expect(viewModel.isLoadingMorePopular == false)
    }

    @Test func testLoadMorePopularStopsWhenNoMoreResults() async {
        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 10, title: "Movie 10")]

        repository.popularResultProvider = { page in
            if page == 1 { return .success(page1) }
            return .success([]) // Page 2 empty
        }

        await viewModel.fetchHomeData()
        await viewModel.loadMorePopularMovies()

        #expect(viewModel.popularMovies.count == 1)
        #expect(viewModel.canLoadMorePopular == false)
    }

    @Test func testLoadMorePopularHandlesError() async {
        struct PageError: Error, LocalizedError {
            var errorDescription: String? { "Rate limit exceeded" }
        }

        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 10, title: "Movie 10")]

        repository.popularResultProvider = { page in
            if page == 1 { return .success(page1) }
            return .failure(PageError())
        }

        await viewModel.fetchHomeData()
        await viewModel.loadMorePopularMovies()

        #expect(viewModel.popularMovies.count == 1) // previous data preserved!
        #expect(viewModel.paginationError == "Rate limit exceeded")
        #expect(viewModel.isLoadingMorePopular == false)
    }

    @Test func testToggleFavoriteUpdatesFavoriteMovieIds() async {
        let (viewModel, _) = makeSUT()
        let movie = makeMovie(id: 42, title: "Interstellar")

        #expect(viewModel.isFavorite(movieId: 42) == false)

        await viewModel.toggleFavorite(movie: movie)
        #expect(viewModel.isFavorite(movieId: 42) == true)

        await viewModel.toggleFavorite(movie: movie)
        #expect(viewModel.isFavorite(movieId: 42) == false)
    }

    @Test func testFetchHomeDataLoadsFavoriteMovieIds() async {
        let (viewModel, repository) = makeSUT()
        let favorite = makeMovie(id: 99, title: "Dune")
        repository.favoritesList = [favorite]

        await viewModel.fetchHomeData()

        #expect(viewModel.isFavorite(movieId: 99) == true)
        #expect(viewModel.isFavorite(movieId: 100) == false)
    }
}
