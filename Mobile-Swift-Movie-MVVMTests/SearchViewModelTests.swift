//
//  SearchViewModelTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct SearchViewModelTests {

    private func makeSUT(
        repository: MockMovieRepository = MockMovieRepository(),
        debounce: Duration = .zero
    ) -> (SearchViewModel, MockMovieRepository) {
        let useCase = SearchMoviesUseCase(repository: repository)
        let discoverUseCase = DiscoverMoviesByGenreUseCase(repository: repository)
        let viewModel = SearchViewModel(
            searchMoviesUseCase: useCase,
            discoverMoviesByGenreUseCase: discoverUseCase,
            debounceDuration: debounce
        )
        return (viewModel, repository)
    }

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview \(id)",
            posterPath: "/poster\(id).jpg",
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 8.0,
            voteCount: 50
        )
    }

    @Test func testInitialStateIsInitial() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.state == .initial)
        #expect(viewModel.movies.isEmpty)
        #expect(viewModel.query.isEmpty)
    }

    @Test func testSearchImmediateSuccessUpdatesStateToLoaded() async {
        let (viewModel, repository) = makeSUT()
        let movies = [makeMovie(id: 1, title: "Inception")]
        repository.searchResult = .success(movies)

        await viewModel.executeSearchImmediate(query: "Inception")

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.movies.first?.title == "Inception")
    }

    @Test func testSearchImmediateEmptyResultsUpdatesStateToEmpty() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([])

        await viewModel.executeSearchImmediate(query: "NonExistentMovieXYZ")

        #expect(viewModel.state == .empty)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func testSearchImmediateErrorUpdatesStateToError() async {
        struct SearchFailure: Error, LocalizedError {
            var errorDescription: String? { "Network timeout" }
        }

        let (viewModel, repository) = makeSUT()
        repository.searchResult = .failure(SearchFailure())

        await viewModel.executeSearchImmediate(query: "Dune")

        #expect(viewModel.state == .error("Network timeout"))
        #expect(viewModel.movies.isEmpty)
    }

    @Test func testClearingQueryResetsStateToInitial() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Batman")])

        await viewModel.executeSearchImmediate(query: "Batman")
        #expect(viewModel.state == .loaded)

        viewModel.query = ""
        #expect(viewModel.state == .initial)
        #expect(viewModel.movies.isEmpty)
    }

    @Test func testLoadMoreAppendsSubsequentPages() async {
        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 1, title: "Movie 1")]
        let page2 = [makeMovie(id: 2, title: "Movie 2")]

        repository.searchResult = .success(page1)
        await viewModel.executeSearchImmediate(query: "Movie")
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.page == 1)

        repository.searchResult = .success(page2)
        await viewModel.loadMore()

        #expect(viewModel.movies.count == 2)
        #expect(viewModel.page == 2)
        #expect(viewModel.movies.map { $0.id } == [1, 2])
    }

    @Test func testSelectGenreFetchesDiscoveryMovies() async {
        let (viewModel, repository) = makeSUT()
        let actionMovies = [makeMovie(id: 10, title: "John Wick")]
        repository.discoverResult = .success(actionMovies)

        let genre = Genre(id: 28, name: "Action")
        await viewModel.selectGenre(genre)

        #expect(viewModel.selectedGenre?.id == 28)
        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.movies.first?.title == "John Wick")
        #expect(repository.requestedDiscoverGenreId == 28)
    }

    @Test func testSelectSameGenreTogglesSelectionOffAndResetsState() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        let genre = Genre(id: 28, name: "Action")
        await viewModel.selectGenre(genre)
        #expect(viewModel.selectedGenre?.id == 28)

        await viewModel.selectGenre(genre)
        #expect(viewModel.selectedGenre == nil)
        #expect(viewModel.movies.isEmpty)
        #expect(viewModel.state == .initial)
    }

    @Test func testLoadMoreWithSelectedGenrePaginatesDiscovery() async {
        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 10, title: "Action 1")]
        let page2 = [makeMovie(id: 11, title: "Action 2")]

        repository.discoverResult = .success(page1)
        let genre = Genre(id: 28, name: "Action")
        await viewModel.selectGenre(genre)
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.page == 1)

        repository.discoverResult = .success(page2)
        await viewModel.loadMore()

        #expect(viewModel.movies.count == 2)
        #expect(viewModel.page == 2)
        #expect(repository.requestedDiscoverPage == 2)
    }
}
