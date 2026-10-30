//
//  AppContainer.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class AppContainer {
    public let movieRepository: MovieRepositoryProtocol

    public init(movieRepository: MovieRepositoryProtocol) {
        self.movieRepository = movieRepository
    }

    public func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            getNowPlayingMoviesUseCase: GetNowPlayingMoviesUseCase(repository: movieRepository),
            getPopularMoviesUseCase: GetPopularMoviesUseCase(repository: movieRepository),
            getTopRatedMoviesUseCase: GetTopRatedMoviesUseCase(repository: movieRepository),
            toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCase(repository: movieRepository),
            getFavoriteMoviesUseCase: GetFavoriteMoviesUseCase(repository: movieRepository)
        )
    }

    public func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(
            searchMoviesUseCase: SearchMoviesUseCase(repository: movieRepository),
            discoverMoviesUseCase: DiscoverMoviesUseCase(repository: movieRepository),
            getGenresUseCase: GetGenresUseCase(repository: movieRepository)
        )
    }

    public func makeDiscoverViewModel() -> DiscoverViewModel {
        DiscoverViewModel(
            discoverMoviesUseCase: DiscoverMoviesUseCase(repository: movieRepository),
            getGenresUseCase: GetGenresUseCase(repository: movieRepository)
        )
    }

    public func makeFavoritesViewModel() -> FavoritesViewModel {
        FavoritesViewModel(
            getFavoriteMoviesUseCase: GetFavoriteMoviesUseCase(repository: movieRepository),
            removeFavoriteMovieUseCase: RemoveFavoriteMovieUseCase(repository: movieRepository)
        )
    }

    public func makeMovieDetailViewModel(movieId: Int) -> MovieDetailViewModel {
        MovieDetailViewModel(
            movieId: movieId,
            getMovieDetailsUseCase: GetMovieDetailsUseCase(repository: movieRepository),
            toggleFavoriteMovieUseCase: ToggleFavoriteMovieUseCase(repository: movieRepository),
            checkIsFavoriteUseCase: CheckIsFavoriteUseCase(repository: movieRepository),
            discoverMoviesUseCase: DiscoverMoviesUseCase(repository: movieRepository)
        )
    }

    public func makePersonViewModel(personId: Int) -> PersonViewModel {
        PersonViewModel(
            personId: personId,
            getPersonProfileUseCase: GetPersonProfileUseCase(repository: movieRepository)
        )
    }
}

#if DEBUG
public extension AppContainer {
    static let preview = AppContainer(movieRepository: PreviewMovieRepository())
}
#endif
