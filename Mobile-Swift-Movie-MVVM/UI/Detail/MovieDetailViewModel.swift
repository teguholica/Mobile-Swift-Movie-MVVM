//
//  MovieDetailViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

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

    private let getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol
    private let toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol
    private let checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol

    public init(
        movieId: Int,
        getMovieDetailsUseCase: GetMovieDetailsUseCaseProtocol,
        toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol,
        checkIsFavoriteUseCase: CheckIsFavoriteUseCaseProtocol
    ) {
        self.movieId = movieId
        self.getMovieDetailsUseCase = getMovieDetailsUseCase
        self.toggleFavoriteMovieUseCase = toggleFavoriteMovieUseCase
        self.checkIsFavoriteUseCase = checkIsFavoriteUseCase
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
        } catch {
            self.state = .error(error.localizedDescription)
        }
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
