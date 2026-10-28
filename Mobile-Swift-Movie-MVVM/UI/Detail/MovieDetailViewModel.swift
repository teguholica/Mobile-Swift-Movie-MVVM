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

    public var selectedGenre: Genre? {
        genreSections.first?.genre
    }

    public var relatedMovies: [Movie] {
        genreSections.first?.movies ?? []
    }

    private let getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol
    private let toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol
    private let checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol
    private let discoverMoviesByGenreUseCase: DiscoverMoviesByGenreUseCaseProtocol

    public init(
        movieId: Int,
        getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol,
        toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol,
        checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol,
        discoverMoviesByGenreUseCase: DiscoverMoviesByGenreUseCaseProtocol
    ) {
        self.movieId = movieId
        self.getMovieDetailsUseCase = getMovieDetailsUseCase
        self.toggleFavoriteMovieUseCase = toggleFavoriteMovieUseCase
        self.checkIsFavoriteUseCase = checkIsFavoriteUseCase
        self.discoverMoviesByGenreUseCase = discoverMoviesByGenreUseCase
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

            await fetchAllGenreSections(for: detail)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    @MainActor
    public func fetchAllGenreSections(for detail: MovieDetail) async {
        guard !detail.genres.isEmpty else {
            self.genreSections = []
            return
        }

        self.isLoadingRelated = true
        let genres = detail.genres

        var resultsByGenreId: [Int: [Movie]] = [:]
        await withTaskGroup(of: (Int, [Movie]).self) { group in
            for genre in genres {
                group.addTask { [discoverUseCase = self.discoverMoviesByGenreUseCase] in
                    do {
                        let movies = try await discoverUseCase.execute(genreId: genre.id, page: 1)
                        return (genre.id, movies)
                    } catch {
                        return (genre.id, [])
                    }
                }
            }

            for await (genreId, movies) in group {
                resultsByGenreId[genreId] = movies
            }
        }

        var sections: [GenreSection] = []
        for genre in genres {
            if let movies = resultsByGenreId[genre.id] {
                let filtered = movies.filter { $0.id != self.movieId }
                if !filtered.isEmpty {
                    sections.append(GenreSection(genre: genre, movies: filtered))
                }
            }
        }

        self.genreSections = sections
        self.isLoadingRelated = false
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
