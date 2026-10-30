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
        let viewModel = SearchViewModel(
            searchMoviesUseCase: useCase,
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
        #expect(viewModel.selectedYear == nil)
    }

    @Test func testSearchImmediateSuccessUpdatesStateToLoaded() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Inception")])

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
        #expect(viewModel.page == 1)

        repository.searchResult = .success(page2)
        await viewModel.loadMore()

        #expect(viewModel.movies.count == 2)
        #expect(viewModel.page == 2)
        #expect(viewModel.movies.map(\.id) == [1, 2])
    }

    @Test func testApplyYearWithQueryRepeatsSearchFromPageOne() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        repository.searchResult = .success([makeMovie(id: 2, title: "Dune Part Two")])
        await viewModel.applyYear(2021)

        #expect(viewModel.selectedYear == 2021)
        #expect(viewModel.page == 1)
        #expect(repository.requestedSearchQuery == "Dune")
        #expect(repository.requestedSearchYear == 2021)
        #expect(viewModel.state == .loaded)
    }

    @Test func testApplyYearResetsPagination() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        repository.searchResult = .success([makeMovie(id: 2, title: "Dune Part Two")])
        await viewModel.loadMore()
        #expect(viewModel.page == 2)

        repository.searchResult = .success([makeMovie(id: 3, title: "Dune 2021")])
        await viewModel.applyYear(2021)

        #expect(viewModel.page == 1)
        #expect(repository.requestedSearchYear == 2021)
        #expect(viewModel.movies.count == 1)
    }

    @Test func testRetryAfterErrorKeepsQueryAndYear() async {
        struct SearchFailure: Error, LocalizedError {
            var errorDescription: String? { "Network down" }
        }

        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        await viewModel.applyYear(2021)

        repository.searchResult = .failure(SearchFailure())
        await viewModel.retry()
        #expect(viewModel.state == .error("Network down"))

        repository.searchResult = .success([makeMovie(id: 2, title: "Dune 2021")])
        await viewModel.retry()

        #expect(viewModel.state == .loaded)
        #expect(repository.requestedSearchQuery == "Dune")
        #expect(repository.requestedSearchYear == 2021)
    }

    @Test func testApplyingSameYearDoesNotRefetch() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        await viewModel.applyYear(2021)
        let calls = repository.searchCallCount

        await viewModel.applyYear(2021)

        #expect(repository.searchCallCount == calls)
    }

    @Test func testApplyYearWithoutQueryStoresOnly() async {
        let (viewModel, repository) = makeSUT()

        await viewModel.applyYear(2021)

        #expect(viewModel.selectedYear == 2021)
        #expect(viewModel.state == .initial)
        #expect(repository.requestedSearchQuery == nil)
    }

    @Test func testSearchPassesSelectedYear() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([])
        viewModel.selectedYear = 2021

        await viewModel.executeSearchImmediate(query: "Dune")

        #expect(repository.requestedSearchYear == 2021)
    }

    @Test func testPaginationKeepsSelectedYear() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        await viewModel.applyYear(2021)

        repository.searchResult = .success([makeMovie(id: 2, title: "Dune Part Two")])
        await viewModel.loadMore()

        #expect(viewModel.page == 2)
        #expect(repository.requestedSearchYear == 2021)
    }

    @Test func testRefreshReusesQueryAndYear() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        await viewModel.applyYear(2021)
        await viewModel.refresh()

        #expect(repository.requestedSearchQuery == "Dune")
        #expect(repository.requestedSearchYear == 2021)
        #expect(viewModel.page == 1)
    }

    @Test func testResetClearsQueryAndYear() async {
        let (viewModel, repository) = makeSUT()
        repository.searchResult = .success([makeMovie(id: 1, title: "Dune")])

        await viewModel.executeSearchImmediate(query: "Dune")
        await viewModel.applyYear(2021)
        await viewModel.reset()

        #expect(viewModel.query.isEmpty)
        #expect(viewModel.selectedYear == nil)
        #expect(viewModel.state == .initial)
        #expect(viewModel.movies.isEmpty)
        #expect(viewModel.page == 1)
    }
}
