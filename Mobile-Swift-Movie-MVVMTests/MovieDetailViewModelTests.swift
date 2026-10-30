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

    private func makeSampleDetail(
        id: Int = 550,
        genres: [Genre] = [Genre(id: 18, name: "Drama"), Genre(id: 53, name: "Thriller")],
        trailer: MovieVideo? = nil,
        cast: [CastMember] = [],
        providers: WatchProviders? = nil,
        recommendedMovies: [Movie] = []
    ) -> MovieDetail {
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
            genres: genres,
            trailer: trailer,
            cast: cast,
            providers: providers,
            recommendedMovies: recommendedMovies
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

    @Test func testViewModelExposesSelectedTrailer() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let trailer = MovieVideo(
            id: "v1",
            key: "abc123",
            name: "Official Trailer",
            site: "YouTube",
            type: "Trailer",
            official: true
        )
        repository.movieDetailsResult = .success(makeSampleDetail(trailer: trailer))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.trailer?.key == "abc123")
    }

    @Test func testViewModelTrailerIsNilWhenDetailHasNoTrailer() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        repository.movieDetailsResult = .success(makeSampleDetail(trailer: nil))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.trailer == nil)
    }

    @Test func testViewModelExposesCast() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let cast = [
            CastMember(id: 1, name: "Brad Pitt", character: "Tyler Durden", profilePath: "/brad.jpg"),
            CastMember(id: 2, name: "Edward Norton", character: "Narrator", profilePath: nil)
        ]
        repository.movieDetailsResult = .success(makeSampleDetail(cast: cast))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.cast.count == 2)
        #expect(viewModel.movieDetail?.cast.first?.character == "Tyler Durden")
    }

    @Test func testViewModelCastIsEmptyWhenDetailHasNoCast() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        repository.movieDetailsResult = .success(makeSampleDetail(cast: []))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.cast.isEmpty == true)
    }

    @Test func testViewModelExposesWatchProviders() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let providers = WatchProviders(
            link: URL(string: "https://www.themoviedb.org/movie/550/watch?locale=US"),
            groups: [
                ProviderGroup(
                    kind: .stream,
                    providers: [WatchProvider(id: 8, name: "Netflix", logoPath: "/netflix.png")]
                )
            ]
        )
        repository.movieDetailsResult = .success(makeSampleDetail(providers: providers))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.providers?.groups.first?.providers.first?.name == "Netflix")
    }

    @Test func testViewModelWatchProvidersNilWhenDetailHasNone() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        repository.movieDetailsResult = .success(makeSampleDetail(providers: nil))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.providers == nil)
    }

    @Test func testFetchDetailsExposesRecommendedMovies() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let related = [
            makeMovie(id: 101, title: "Se7en"),
            makeMovie(id: 102, title: "The Game")
        ]
        repository.movieDetailsResult = .success(makeSampleDetail(recommendedMovies: related))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.recommendedMovies.map(\.id) == [101, 102])
    }

    @Test func testFetchDetailsBuildsGenreSections() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let dramaMovies = [makeMovie(id: 101, title: "Drama One"), makeMovie(id: 102, title: "Drama Two")]
        let thrillerMovies = [makeMovie(id: 201, title: "Thriller One")]
        repository.movieDetailsResult = .success(makeSampleDetail())
        repository.discoverResultProvider = { genreId in
            switch genreId {
            case 18: return .success(dramaMovies)
            case 53: return .success(thrillerMovies)
            default: return .success([])
            }
        }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.map(\.genre.name) == ["Drama", "Thriller"])
        #expect(viewModel.genreSections[0].movies.map(\.id) == [101, 102])
        #expect(viewModel.genreSections[1].movies.map(\.id) == [201])
        #expect(viewModel.isLoadingRelated == false)
        #expect(repository.getMovieDetailsCallCount == 1)
    }

    @Test func testGenreSectionsExcludeCurrentMovie() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let movies = [makeMovie(id: 550, title: "Fight Club"), makeMovie(id: 101, title: "Se7en")]
        repository.movieDetailsResult = .success(makeSampleDetail())
        repository.discoverResultProvider = { _ in .success(movies) }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.allSatisfy { section in
            section.movies.allSatisfy { $0.id != 550 }
        })
        #expect(viewModel.genreSections.allSatisfy { $0.movies.map(\.id) == [101] })
    }

    @Test func testFailedGenreDiscoverIsIgnored() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        let thrillerMovies = [makeMovie(id: 201, title: "Thriller One")]
        repository.movieDetailsResult = .success(makeSampleDetail())
        repository.discoverResultProvider = { genreId in
            genreId == 18 ? .failure(URLError(.badServerResponse)) : .success(thrillerMovies)
        }

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.map(\.genre.id) == [53])
        #expect(viewModel.isLoadingRelated == false)
    }

    @Test func testGenreSectionsEmptyWhenDetailHasNoGenres() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        repository.movieDetailsResult = .success(makeSampleDetail(genres: []))

        await viewModel.fetchDetails()

        #expect(viewModel.genreSections.isEmpty)
        #expect(repository.requestedDiscoverGenreId == nil)
        #expect(viewModel.isLoadingRelated == false)
    }

    @Test func testRecommendedMoviesEmptyWhenNone() async {
        let (viewModel, repository) = makeSUT(movieId: 550)
        repository.movieDetailsResult = .success(makeSampleDetail(recommendedMovies: []))

        await viewModel.fetchDetails()

        #expect(viewModel.movieDetail?.recommendedMovies.isEmpty == true)
    }
}
