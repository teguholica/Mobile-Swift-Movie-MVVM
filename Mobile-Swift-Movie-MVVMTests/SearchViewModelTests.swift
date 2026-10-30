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
        let discoverUseCase = DiscoverMoviesUseCase(repository: repository)
        let getGenresUseCase = GetGenresUseCase(repository: repository)
        let viewModel = SearchViewModel(
            searchMoviesUseCase: useCase,
            discoverMoviesUseCase: discoverUseCase,
            getGenresUseCase: getGenresUseCase,
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

    @Test func testToggleGenreFetchesDiscoveryMovies() async {
        let (viewModel, repository) = makeSUT()
        let actionMovies = [makeMovie(id: 10, title: "John Wick")]
        repository.discoverResult = .success(actionMovies)

        let genre = Genre(id: 28, name: "Action")
        await viewModel.toggleGenre(genre)

        #expect(viewModel.selectedGenres.map(\.id) == [28])
        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.movies.first?.title == "John Wick")
        #expect(repository.requestedDiscoverFilters?.genreIds == [28])
        #expect(repository.requestedDiscoverFilters?.sort == .popularity)
    }

    @Test func testToggleSameGenreOffResetsState() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        let genre = Genre(id: 28, name: "Action")
        await viewModel.toggleGenre(genre)
        #expect(viewModel.selectedGenres.map(\.id) == [28])

        await viewModel.toggleGenre(genre)
        #expect(viewModel.selectedGenres.isEmpty)
        #expect(viewModel.movies.isEmpty)
        #expect(viewModel.state == .initial)
    }

    @Test func testToggleMultipleGenresSendsAllGenreIds() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        await viewModel.toggleGenre(Genre(id: 28, name: "Action"))
        await viewModel.toggleGenre(Genre(id: 35, name: "Comedy"))

        #expect(viewModel.selectedGenres.map(\.id) == [28, 35])
        #expect(repository.requestedDiscoverFilters?.genreIds == [28, 35])
    }

    @Test func testGenresStartFromPresets() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.genres == Genre.popularPresets)
    }

    @Test func testLoadGenresReplacesPresets() async {
        let (viewModel, repository) = makeSUT()
        repository.genresResult = .success([
            Genre(id: 28, name: "Action"),
            Genre(id: 37, name: "Western")
        ])

        await viewModel.loadGenres()

        #expect(viewModel.genres.map(\.name) == ["Action", "Western"])
    }

    @Test func testLoadGenresPreservesSelectedGenreByID() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])
        let preset = Genre(id: 878, name: "Sci-Fi")
        await viewModel.toggleGenre(preset)

        repository.genresResult = .success([
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 37, name: "Western")
        ])
        await viewModel.loadGenres()

        #expect(viewModel.isSelected(preset))
        #expect(viewModel.selectedGenres.first?.name == "Science Fiction")
        #expect(viewModel.genres.map(\.id) == [878, 37])
    }

    @Test func testLoadGenresRequestsCatalogueOnce() async {
        let (viewModel, repository) = makeSUT()
        repository.genresResult = .success([Genre(id: 28, name: "Action")])

        await viewModel.loadGenres()
        await viewModel.loadGenres()

        #expect(repository.getGenresCallCount == 1)
    }

    @Test func testLoadGenresFailureKeepsPresetsAndState() async {
        struct CatalogueFailure: Error {}

        let (viewModel, repository) = makeSUT()
        repository.genresResult = .failure(CatalogueFailure())

        await viewModel.loadGenres()
        await viewModel.loadGenres()

        #expect(viewModel.genres == Genre.popularPresets)
        #expect(viewModel.state == .initial)
        #expect(repository.getGenresCallCount == 1)
    }

    @Test func testRapidGenreTogglesCoalesceIntoOneRequest() async {
        let (viewModel, repository) = makeSUT(debounce: .milliseconds(500))
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        let first = Task { await viewModel.toggleGenre(Genre(id: 28, name: "Action")) }
        try? await Task.sleep(for: .milliseconds(50))
        let second = Task { await viewModel.toggleGenre(Genre(id: 35, name: "Comedy")) }
        _ = await (first.value, second.value)

        #expect(repository.requestedDiscoverFiltersHistory.map(\.genreIds) == [[28, 35]])
        #expect(repository.discoverCallCount == 1)
    }

    @Test func testSelectingGenreClearsQuery() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Batman")])
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        await viewModel.executeSearchImmediate(query: "Batman")
        await viewModel.toggleGenre(Genre(id: 28, name: "Action"))

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.selectedGenres.map(\.id) == [28])
    }

    @Test func testTypingQueryClearsSelectedGenres() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 10, title: "John Wick")])

        await viewModel.toggleGenre(Genre(id: 28, name: "Action"))
        #expect(viewModel.selectedGenres.map(\.id) == [28])

        viewModel.query = "Dune"

        #expect(viewModel.selectedGenres.isEmpty)
    }

    @Test func testLoadMoreWithSelectedGenresPaginatesDiscovery() async {
        let (viewModel, repository) = makeSUT()
        let page1 = [makeMovie(id: 10, title: "Action 1")]
        let page2 = [makeMovie(id: 11, title: "Action 2")]

        repository.discoverResult = .success(page1)
        await viewModel.toggleGenre(Genre(id: 28, name: "Action"))
        #expect(viewModel.movies.count == 1)
        #expect(viewModel.page == 1)

        repository.discoverResult = .success(page2)
        await viewModel.loadMore()

        #expect(viewModel.movies.count == 2)
        #expect(viewModel.page == 2)
        #expect(repository.requestedDiscoverPage == 2)
        #expect(repository.requestedDiscoverFilters?.genreIds == [28])
    }
}
