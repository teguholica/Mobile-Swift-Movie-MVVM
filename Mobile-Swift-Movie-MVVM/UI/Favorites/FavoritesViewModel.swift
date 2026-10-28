//
//  FavoritesViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class FavoritesViewModel {
    public var favorites: [Movie] = []
    public var softHiddenMovieIds: Set<Int> = []
    public var toastMovie: Movie? = nil
    public var isLoading: Bool = false
    public var errorMessage: String? = nil

    public var visibleFavorites: [Movie] {
        favorites.filter { !softHiddenMovieIds.contains($0.id) }
    }

    private let getFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol
    private let removeFavoriteMovieUseCase: RemoveFavoriteMovieUseCaseProtocol
    private var pendingRemovalTasks: [Int: Task<Void, Never>] = [:]

    public init(
        getFavoriteMoviesUseCase: GetFavoriteMoviesUseCaseProtocol,
        removeFavoriteMovieUseCase: RemoveFavoriteMovieUseCaseProtocol
    ) {
        self.getFavoriteMoviesUseCase = getFavoriteMoviesUseCase
        self.removeFavoriteMovieUseCase = removeFavoriteMovieUseCase
    }

    @MainActor
    public func fetchFavorites() async {
        isLoading = true
        errorMessage = nil
        do {
            self.favorites = try await getFavoriteMoviesUseCase.execute()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    @MainActor
    public func stageRemoval(movie: Movie, delayDuration: Duration = .seconds(4)) {
        pendingRemovalTasks[movie.id]?.cancel()

        softHiddenMovieIds.insert(movie.id)
        toastMovie = movie

        let movieId = movie.id
        pendingRemovalTasks[movieId] = Task { @MainActor [weak self] in
            do {
                if delayDuration > .zero {
                    try await Task.sleep(for: delayDuration)
                }
            } catch {
                return // Cancelled by undo
            }

            guard let self, !Task.isCancelled else { return }
            await self.commitRemoval(movie: movie)
        }
    }

    @MainActor
    public func undoRemoval() {
        guard let movie = toastMovie else { return }
        pendingRemovalTasks[movie.id]?.cancel()
        pendingRemovalTasks.removeValue(forKey: movie.id)
        softHiddenMovieIds.remove(movie.id)
        toastMovie = nil
    }

    @MainActor
    public func commitRemoval(movie: Movie) async {
        pendingRemovalTasks[movie.id]?.cancel()
        pendingRemovalTasks.removeValue(forKey: movie.id)
        do {
            try await removeFavoriteMovieUseCase.execute(movieId: movie.id)
            favorites.removeAll { $0.id == movie.id }
            softHiddenMovieIds.remove(movie.id)
            if toastMovie?.id == movie.id {
                toastMovie = nil
            }
        } catch {
            self.errorMessage = error.localizedDescription
            softHiddenMovieIds.remove(movie.id)
        }
    }

    @MainActor
    public func removeFavorite(movie: Movie) async {
        await commitRemoval(movie: movie)
    }

    @MainActor
    public func removeFavorites(at offsets: IndexSet) async {
        for index in offsets {
            if index < visibleFavorites.count {
                let movie = visibleFavorites[index]
                await commitRemoval(movie: movie)
            }
        }
    }
}
