//
//  MovieDetailViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

public struct GenreSection: Identifiable, Equatable, Sendable {
    public let genre: Genre
    public let movies: [Movie]

    public var id: Int { genre.id }

    public init(genre: Genre, movies: [Movie]) {
        self.genre = genre
        self.movies = movies
    }
}

@Observable
public final class MovieDetailViewModel {
    public enum State: Equatable {
        case loading
        case loaded(MovieDetail)
        case error(String)
    }

    public let movieId: Int
    public var state: State = .loading
    public var movieDetail: MovieDetail?
    public var isFavorite: Bool = false
    public var genreSections: [GenreSection] = []
    public var isLoadingRelated: Bool = false

    private let getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol
    private let toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol
    private let checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol
    private let discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol

    public init(
        movieId: Int,
        getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol,
        toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol,
        checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol,
        discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol
    ) {
        self.movieId = movieId
        self.getMovieDetailsUseCase = getMovieDetailsUseCase
        self.toggleFavoriteMovieUseCase = toggleFavoriteMovieUseCase
        self.checkIsFavoriteUseCase = checkIsFavoriteUseCase
        self.discoverMoviesUseCase = discoverMoviesUseCase
    }

    @MainActor
    public func fetchDetails() async {
        if movieDetail == nil {
            state = .loading
        }

        do {
            async let detailTask = getMovieDetailsUseCase.execute(id: movieId)
            async let favoriteTask = checkIsFavoriteUseCase.execute(movieId: movieId)

            let (detail, favoriteStatus) = try await (detailTask, favoriteTask)
            self.movieDetail = detail
            self.isFavorite = favoriteStatus
            self.state = .loaded(detail)

            await fetchGenreSections(for: detail)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    @MainActor
    public func fetchGenreSections(for detail: MovieDetail) async {
        let genres = detail.genres
        guard !genres.isEmpty else {
            genreSections = []
            return
        }

        isLoadingRelated = true
        let discoverUseCase = discoverMoviesUseCase
        let currentMovieId = movieId

        var moviesByGenreId: [Int: [Movie]] = [:]
        await withTaskGroup(of: (Int, [Movie]).self) { group in
            for genre in genres {
                group.addTask {
                    do {
                        let movies = try await discoverUseCase.execute(
                            filters: DiscoverFilters(genreIds: [genre.id]),
                            page: 1
                        )
                        return (genre.id, movies)
                    } catch {
                        return (genre.id, [])
                    }
                }
            }

            for await (genreId, movies) in group {
                moviesByGenreId[genreId] = movies
            }
        }

        var sections: [GenreSection] = []
        for genre in genres {
            let movies = (moviesByGenreId[genre.id] ?? []).filter { $0.id != currentMovieId }
            if !movies.isEmpty {
                sections.append(GenreSection(genre: genre, movies: movies))
            }
        }

        genreSections = sections
        isLoadingRelated = false
    }

    @MainActor
    public func toggleFavorite() async {
        guard let detail = movieDetail else { return }
        let movie = Movie(
            id: detail.id,
            title: detail.title,
            overview: detail.overview,
            posterPath: detail.posterPath,
            backdropPath: detail.backdropPath,
            releaseDate: detail.releaseDate,
            voteAverage: detail.voteAverage,
            voteCount: detail.voteCount
        )

        do {
            let newStatus = try await toggleFavoriteMovieUseCase.execute(movie: movie)
            self.isFavorite = newStatus
        } catch {
            // Error toggling favorite can be silently handled or reported
        }
    }
}
