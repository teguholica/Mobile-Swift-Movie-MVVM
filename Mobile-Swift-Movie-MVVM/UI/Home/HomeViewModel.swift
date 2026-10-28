//
//  HomeViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class HomeViewModel {
    public enum State: Equatable {
        case idle
        case loading
        case loaded
        case error(String)
    }

    public var state: State = .idle
    public var nowPlayingMovies: [Movie] = []
    public var popularMovies: [Movie] = []
    public var topRatedMovies: [Movie] = []
    public var favoriteMovieIds: Set<Int> = []

    public var popularPage: Int = 1
    public var isLoadingMorePopular: Bool = false
    public var canLoadMorePopular: Bool = true
    public var paginationError: String? = nil

    private let getNowPlayingMoviesUseCase: GetNowPlayingMoviesUseCaseProtocol
    private let getPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol
    private let getTopRatedMoviesUseCase: GetTopRatedMoviesUseCaseProtocol
    private let toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol?
    private let getFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol?

    public init(
        getNowPlayingMoviesUseCase: GetNowPlayingMoviesUseCaseProtocol,
        getPopularMoviesUseCase: GetPopularMoviesUseCaseProtocol,
        getTopRatedMoviesUseCase: GetTopRatedMoviesUseCaseProtocol,
        toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCaseProtocol? = nil,
        getFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol? = nil
    ) {
        self.getNowPlayingMoviesUseCase = getNowPlayingMoviesUseCase
        self.getPopularMoviesUseCase = getPopularMoviesUseCase
        self.getTopRatedMoviesUseCase = getTopRatedMoviesUseCase
        self.toggleFavoriteMovieUseCase = toggleFavoriteMovieUseCase
        self.getFavoriteMoviesUseCase = getFavoriteMoviesUseCase
    }

    public func isFavorite(movieId: Int) -> Bool {
        favoriteMovieIds.contains(movieId)
    }

    @MainActor
    public func toggleFavorite(movie: Movie) async {
        guard let toggleFavoriteMovieUseCase else { return }
        do {
            let isFav = try await toggleFavoriteMovieUseCase.execute(movie: movie)
            if isFav {
                favoriteMovieIds.insert(movie.id)
            } else {
                favoriteMovieIds.remove(movie.id)
            }
        } catch {
            // Non-fatal error; UI retains existing state
        }
    }

    @MainActor
    public func fetchHomeData() async {
        if nowPlayingMovies.isEmpty && popularMovies.isEmpty && topRatedMovies.isEmpty {
            state = .loading
        }
        paginationError = nil
        popularPage = 1
        canLoadMorePopular = true

        do {
            async let nowPlaying = getNowPlayingMoviesUseCase.execute(page: 1)
            async let popular = getPopularMoviesUseCase.execute(page: 1)
            async let topRated = getTopRatedMoviesUseCase.execute(page: 1)

            let (nowPlayingResult, popularResult, topRatedResult) = try await (nowPlaying, popular, topRated)

            self.nowPlayingMovies = nowPlayingResult
            self.popularMovies = popularResult
            self.topRatedMovies = topRatedResult

            if let getFavoriteMoviesUseCase {
                if let favorites = try? await getFavoriteMoviesUseCase.execute() {
                    self.favoriteMovieIds = Set(favorites.map { $0.id })
                }
            }

            self.state = .loaded
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    @MainActor
    public func loadMorePopularMovies() async {
        guard !isLoadingMorePopular && canLoadMorePopular && !popularMovies.isEmpty else { return }

        isLoadingMorePopular = true
        paginationError = nil
        let nextPage = popularPage + 1

        do {
            let nextMovies = try await getPopularMoviesUseCase.execute(page: nextPage)
            if nextMovies.isEmpty {
                canLoadMorePopular = false
            } else {
                let existingIds = Set(popularMovies.map { $0.id })
                let newUniqueMovies = nextMovies.filter { !existingIds.contains($0.id) }
                self.popularMovies.append(contentsOf: newUniqueMovies)
                self.popularPage = nextPage
            }
        } catch {
            self.paginationError = error.localizedDescription
        }

        self.isLoadingMorePopular = false
    }

    @MainActor
    public func retryLoadMorePopular() async {
        await loadMorePopularMovies()
    }
}
