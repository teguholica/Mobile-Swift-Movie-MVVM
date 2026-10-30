//
//  DiscoverViewModelTests.swift
//  Mobile-Swift-Movie-MVVM
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct DiscoverViewModelTests {

    private func makeSUT(
        repository: MockMovieRepository = MockMovieRepository()
    ) -> (DiscoverViewModel, MockMovieRepository) {
        let viewModel = DiscoverViewModel(
            discoverMoviesUseCase: DiscoverMoviesUseCase(repository: repository),
            getGenresUseCase: GetGenresUseCase(repository: repository)
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
            voteCount: 100
        )
    }

    @Test func testInitialStateIsLoading() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.state == .loading)
        #expect(viewModel.movies.isEmpty)
        #expect(viewModel.filters == DiscoverFilters())
        #expect(viewModel.activeFilterCount == 0)
    }

    @Test func testLoadInitialRequestsDefaultCatalogue() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])

        await viewModel.loadInitial()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.count == 1)
        #expect(repository.requestedDiscoverFilters == DiscoverFilters())
        #expect(repository.requestedDiscoverPage == 1)
    }

    @Test func testLoadInitialRunsOnlyOnce() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])

        await viewModel.loadInitial()
        await viewModel.loadInitial()

        #expect(repository.discoverCallCount == 1)
    }

    @Test func testApplyFiltersCommitsAdvancedFilters() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])

        await viewModel.loadInitial()
        await viewModel.applyFilters(
            DiscoverFilters(yearRange: 2000...2010, minRating: 7.0, sort: .rating)
        )

        #expect(viewModel.filters.yearRange == 2000...2010)
        #expect(viewModel.filters.minRating == 7.0)
        #expect(viewModel.filters.sort == .rating)
        #expect(viewModel.activeFilterCount == 3)
        #expect(viewModel.page == 1)
        #expect(repository.requestedDiscoverFilters?.yearRange == 2000...2010)
        #expect(repository.requestedDiscoverFilters?.minRating == 7.0)
        #expect(repository.requestedDiscoverFilters?.sort == .rating)
    }

    @Test func testApplyCategoryMapsIdentifiersAndExcludesCategoryFromCount() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Action")])

        await viewModel.applyCategory([28, 35])

        #expect(viewModel.selectedGenres.map(\.id) == [28, 35])
        #expect(viewModel.activeFilterCount == 0)
        #expect(viewModel.categorySummary == "Category: Action +1")
        #expect(viewModel.categoryAccessibilityLabel == "Category: Action, Comedy")
        #expect(repository.requestedDiscoverFilters?.genreIds == [28, 35])
    }

    @Test func testPaginationKeepsFiltersAndCategory() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Action 1")])

        await viewModel.applyCategory([28])
        await viewModel.applyFilters(DiscoverFilters(genreIds: [28], minRating: 7.0))

        repository.discoverResult = .success([makeMovie(id: 2, title: "Action 2")])
        await viewModel.loadMore()

        #expect(viewModel.page == 2)
        #expect(repository.requestedDiscoverPage == 2)
        #expect(repository.requestedDiscoverFilters?.genreIds == [28])
        #expect(repository.requestedDiscoverFilters?.minRating == 7.0)
    }

    @Test func testFilterApplyPreservesSelectedCategory() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Action")])

        await viewModel.applyCategory([28])
        await viewModel.applyFilters(DiscoverFilters(minRating: 7.0))

        #expect(viewModel.selectedGenres.map(\.id) == [28])
        #expect(repository.requestedDiscoverFilters?.genreIds == [28])
        #expect(repository.requestedDiscoverFilters?.minRating == 7.0)
    }

    @Test func testResetReloadsDefaultCatalogue() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])

        await viewModel.loadInitial()
        await viewModel.applyFilters(
            DiscoverFilters(genreIds: [28], yearRange: 2000...2010, minRating: 7.0)
        )
        let callsBeforeReset = repository.discoverCallCount

        await viewModel.resetAll()

        #expect(viewModel.filters == DiscoverFilters())
        #expect(viewModel.selectedGenres.isEmpty)
        #expect(viewModel.state == .loaded)
        #expect(repository.requestedDiscoverFilters == DiscoverFilters())
        #expect(repository.discoverCallCount > callsBeforeReset)
    }

    @Test func testEmptyStateThenResetReloadsDefault() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([])

        await viewModel.applyFilters(DiscoverFilters(minRating: 9.0))
        #expect(viewModel.state == .empty)

        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])
        await viewModel.resetAll()

        #expect(viewModel.state == .loaded)
        #expect(repository.requestedDiscoverFilters == DiscoverFilters())
    }

    @Test func testErrorStateThenRetryLoadsResults() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .failure(URLError(.badServerResponse))

        await viewModel.loadInitial()
        #expect(viewModel.state != .loaded)

        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])
        await viewModel.refresh()

        #expect(viewModel.state == .loaded)
        #expect(viewModel.movies.count == 1)
    }

    @Test func testRefreshReusesCommittedFilters() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Popular")])

        await viewModel.applyFilters(DiscoverFilters(yearRange: 2000...2010))
        await viewModel.refresh()

        #expect(repository.requestedDiscoverFilters?.yearRange == 2000...2010)
        #expect(repository.requestedDiscoverPage == 1)
        #expect(viewModel.page == 1)
    }

    @Test func testLoadGenresRequestsCatalogueOnce() async {
        let (viewModel, repository) = makeSUT()
        repository.genresResult = .success([Genre(id: 28, name: "Action")])

        await viewModel.loadGenres()
        await viewModel.loadGenres()

        #expect(repository.getGenresCallCount == 1)
    }

    @Test func testLoadGenresFailureKeepsPresets() async {
        struct CatalogueFailure: Error {}

        let (viewModel, repository) = makeSUT()
        repository.genresResult = .failure(CatalogueFailure())

        await viewModel.loadGenres()

        #expect(viewModel.genres == Genre.popularPresets)
    }

    @Test func testLoadGenresPreservesSelectedCategoryByID() async {
        let (viewModel, repository) = makeSUT()
        repository.discoverResult = .success([makeMovie(id: 1, title: "Sci-Fi")])

        await viewModel.applyCategory([878])

        repository.genresResult = .success([
            Genre(id: 878, name: "Science Fiction"),
            Genre(id: 37, name: "Western")
        ])
        await viewModel.loadGenres()

        #expect(viewModel.selectedGenres.map(\.id) == [878])
        #expect(viewModel.selectedGenres.first?.name == "Science Fiction")
        #expect(viewModel.categorySummary == "Category: Science Fiction")
    }
}
