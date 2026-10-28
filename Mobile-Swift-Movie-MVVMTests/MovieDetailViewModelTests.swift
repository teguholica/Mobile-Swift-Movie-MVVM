//
//  MovieDetailViewModelTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct MovieDetailViewModelTests {

    private func makeSUT(
        movieId: Int = 550,
        repository: MockMovieRepository = MockMovieRepository()
    ) -> (MovieDetailViewModel, MockMovieRepository) {
        let detailUseCase = GetMovieDetailsUseCase(repository: repository)
        let toggleUseCase = ToggleFavoriteMovieUseCase(repository: repository)
        let checkUseCase = CheckIsFavoriteUseCase(repository: repository)
        let viewModel = MovieDetailViewModel(
            movieId: movieId,
            getMovieDetailsUseCase: detailUseCase,
            toggleFavoriteMovieUseCase: toggleUseCase,
            checkIsFavoriteUseCase: checkUseCase
        )
        return (viewModel, repository)
    }

    private func makeSampleDetail(id: Int = 550) -> MovieDetail {
        MovieDetail(
            id: id,
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
    }

    @Test func testInitialStateIsLoading() {
        let (viewModel, _) = makeSUT(movieId: 550)

        #expect(viewModel.state == .loading)
        #expect(viewModel.movieDetail == nil)
        #expect(viewModel.movieId == 550)
        #expect(viewModel.isFavorite == false)
    }

    @Test func testFetchDetailsSuccessUpdatesStateToLoaded() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550)
        repository.movieDetailsResult = .success(detail)

        await viewModel.fetchDetails()

        #expect(viewModel.state == .loaded(detail))
        #expect(viewModel.movieDetail?.title == "Fight Club")
        #expect(viewModel.movieDetail?.formattedRuntime == "2h 19m")
        #expect(viewModel.isFavorite == false)
    }

    @Test func testFetchDetailsFailureUpdatesStateToError() async {
        struct FetchError: Error, LocalizedError {
            var errorDescription: String? { "Movie not found" }
        }

        let (viewModel, repository) = makeSUT(movieId: 999)
        repository.movieDetailsResult = .failure(FetchError())

        await viewModel.fetchDetails()

        #expect(viewModel.state == .error("Movie not found"))
        #expect(viewModel.movieDetail == nil)
    }

    @Test func testToggleFavoriteUpdatesFavoriteState() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550)
        repository.movieDetailsResult = .success(detail)

        await viewModel.fetchDetails()
        #expect(viewModel.isFavorite == false)

        await viewModel.toggleFavorite()
        #expect(viewModel.isFavorite == true)

        await viewModel.toggleFavorite()
        #expect(viewModel.isFavorite == false)
    }
}
