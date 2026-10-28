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
        let discoverUseCase = DiscoverMoviesByGenreUseCase(repository: repository)
        let viewModel = MovieDetailViewModel(
            movieId: movieId,
            getMovieDetailsUseCase: detailUseCase,
            toggleFavoriteMovieUseCase: toggleUseCase,
            checkIsFavoriteUseCase: checkUseCase,
            discoverMoviesByGenreUseCase: discoverUseCase
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
            genres: [Genre(id: 18, name: "Drama"), Genre(id: 53, name: "Thriller")]
        )
    }

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview for \(title)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: "2020-01-01",
            voteAverage: 7.5,
            voteCount: 1200
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

    @Test func testFetchDetailsLoadsAllGenreSectionsConcurrently() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550) // Has Drama (18) and Thriller (53)
        repository.movieDetailsResult = .success(detail)
        repository.discoverResultProvider = { genreId in
            if genreId == 18 {
                return .success([self.makeMovie(id: 101, title: "The Godfather"), self.makeMovie(id: 102, title: "Pulp Fiction")])
            } else if genreId == 53 {
                return .success([self.makeMovie(id: 201, title: "Shutter Island")])
            }
            return .success([])
        }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.count == 2)
        #expect(viewModel.genreSections[0].genre.id == 18)
        #expect(viewModel.genreSections[0].genre.name == "Drama")
        #expect(viewModel.genreSections[0].movies.count == 2)
        #expect(viewModel.genreSections[0].movies.first?.title == "The Godfather")

        #expect(viewModel.genreSections[1].genre.id == 53)
        #expect(viewModel.genreSections[1].genre.name == "Thriller")
        #expect(viewModel.genreSections[1].movies.count == 1)
        #expect(viewModel.genreSections[1].movies.first?.title == "Shutter Island")
        #expect(viewModel.isLoadingRelated == false)
    }

    @Test func testGenreSectionsFilterOutCurrentMovie() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550)
        repository.movieDetailsResult = .success(detail)
        let sameMovie = makeMovie(id: 550, title: "Fight Club")
        let anotherMovie = makeMovie(id: 101, title: "Se7en")
        repository.discoverResultProvider = { genreId in
            .success([sameMovie, anotherMovie])
        }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.allSatisfy { section in
            !section.movies.contains(where: { $0.id == 550 })
        })
        #expect(viewModel.genreSections.first?.movies.count == 1)
        #expect(viewModel.genreSections.first?.movies.first?.id == 101)
    }

    @Test func testGenreSectionOmittedIfNoMoviesFound() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550) // Drama (18), Thriller (53)
        repository.movieDetailsResult = .success(detail)
        repository.discoverResultProvider = { genreId in
            if genreId == 18 {
                return .success([self.makeMovie(id: 101, title: "Drama Movie")])
            }
            return .success([]) // Thriller returns nothing
        }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.count == 1)
        #expect(viewModel.genreSections.first?.genre.id == 18)
    }

    @Test func testFailureInOneGenreDoesNotBreakOtherGenreSections() async {
        struct NetworkFailure: Error {}

        let (viewModel, repository) = makeSUT(movieId: 550)
        let detail = makeSampleDetail(id: 550) // Drama (18), Thriller (53)
        repository.movieDetailsResult = .success(detail)
        repository.discoverResultProvider = { genreId in
            if genreId == 18 {
                return .failure(NetworkFailure())
            }
            return .success([self.makeMovie(id: 201, title: "Shutter Island")])
        }

        await viewModel.fetchDetails()

        #expect(viewModel.state == .loaded(detail))
        #expect(viewModel.genreSections.count == 1)
        #expect(viewModel.genreSections.first?.genre.id == 53)
        #expect(viewModel.isLoadingRelated == false)
    }

    @Test func testDetailWithEmptyGenresResultsInEmptyGenreSections() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let detailNoGenres = MovieDetail(
            id: 550,
            title: "Indie Title",
            overview: "No genres",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-01-01",
            voteAverage: 6.0,
            voteCount: 10,
            runtime: 90,
            tagline: nil,
            status: "Released",
            genres: []
        )
        repository.movieDetailsResult = .success(detailNoGenres)

        await viewModel.fetchDetails()

        #expect(viewModel.state == .loaded(detailNoGenres))
        #expect(viewModel.genreSections.isEmpty)
        #expect(viewModel.isLoadingRelated == false)
    }
}
