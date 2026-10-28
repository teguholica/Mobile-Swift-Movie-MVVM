//
//  SearchViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class SearchViewModel {
    public enum State: Equatable {
        case initial
        case loading
        case empty
        case loaded
        case error(String)
    }

    public var query: String = "" {
        didSet {
            onQueryChanged(query)
        }
    }

    public var selectedGenre: Genre? = nil
    public var state: State = .initial
    public var movies: [Movie] = []
    public var page: Int = 1
    public var isLoadingMore: Bool = false
    public var canLoadMore: Bool = true

    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private let discoverMoviesByGenreUseCase: DiscoverMoviesByGenreUseCaseProtocol?
    private let debounceDuration: Duration
    private var searchTask: Task<Void, Never>?

    public init(
        searchMoviesUseCase: SearchMoviesUseCaseProtocol,
        discoverMoviesByGenreUseCase: DiscoverMoviesByGenreUseCaseProtocol? = nil,
        debounceDuration: Duration = .milliseconds(500)
    ) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.discoverMoviesByGenreUseCase = discoverMoviesByGenreUseCase
        self.debounceDuration = debounceDuration
    }

    public func onQueryChanged(_ newQuery: String) {
        searchTask?.cancel()

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if let selectedGenre {
                // If query cleared but genre is selected, re-fetch genre discovery
                Task { @MainActor in
                    await fetchGenreDiscovery(genre: selectedGenre)
                }
            } else {
                movies = []
                state = .initial
                page = 1
                canLoadMore = true
            }
            return
        }

        // Active text search clears the genre selection
        selectedGenre = nil

        searchTask = Task { @MainActor in
            do {
                if debounceDuration > .zero {
                    try await Task.sleep(for: debounceDuration)
                }
            } catch {
                return // Task cancelled
            }

            guard !Task.isCancelled else { return }

            state = .loading
            do {
                let results = try await searchMoviesUseCase.execute(query: trimmed, page: 1)
                guard !Task.isCancelled else { return }

                self.movies = results
                self.page = 1
                self.canLoadMore = !results.isEmpty

                if results.isEmpty {
                    self.state = .empty
                } else {
                    self.state = .loaded
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .error(error.localizedDescription)
            }
        }
    }

    @MainActor
    public func selectGenre(_ genre: Genre?) async {
        searchTask?.cancel()

        // Toggle selection off if already selected
        if let current = selectedGenre, let new = genre, current.id == new.id {
            selectedGenre = nil
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                movies = []
                state = .initial
                page = 1
                canLoadMore = true
            } else {
                await executeSearchImmediate(query: query)
            }
            return
        }

        selectedGenre = genre

        guard let genre else {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                movies = []
                state = .initial
                page = 1
                canLoadMore = true
            }
            return
        }

        // Clear query text input when a genre pill is tapped
        query = ""
        await fetchGenreDiscovery(genre: genre)
    }

    @MainActor
    private func fetchGenreDiscovery(genre: Genre) async {
        guard let discoverMoviesByGenreUseCase else {
            state = .empty
            return
        }

        state = .loading
        do {
            let results = try await discoverMoviesByGenreUseCase.execute(genreId: genre.id, page: 1)
            self.movies = results
            self.page = 1
            self.canLoadMore = !results.isEmpty
            self.state = results.isEmpty ? .empty : .loaded
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }

    @MainActor
    public func loadMore() async {
        guard !isLoadingMore && canLoadMore && !movies.isEmpty else { return }

        isLoadingMore = true
        let nextPage = page + 1

        do {
            let nextResults: [Movie]
            if let selectedGenre, let discoverMoviesByGenreUseCase {
                nextResults = try await discoverMoviesByGenreUseCase.execute(genreId: selectedGenre.id, page: nextPage)
            } else {
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    isLoadingMore = false
                    return
                }
                nextResults = try await searchMoviesUseCase.execute(query: trimmed, page: nextPage)
            }

            if nextResults.isEmpty {
                canLoadMore = false
            } else {
                let existingIds = Set(movies.map { $0.id })
                let newUnique = nextResults.filter { !existingIds.contains($0.id) }
                self.movies.append(contentsOf: newUnique)
                self.page = nextPage
            }
        } catch {
            // Keep existing results intact on pagination error
        }

        isLoadingMore = false
    }

    @MainActor
    public func executeSearchImmediate(query: String) async {
        self.query = query
        self.selectedGenre = nil
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            movies = []
            state = .initial
            return
        }

        state = .loading
        do {
            let results = try await searchMoviesUseCase.execute(query: trimmed, page: 1)
            self.movies = results
            self.page = 1
            self.canLoadMore = !results.isEmpty
            self.state = results.isEmpty ? .empty : .loaded
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }
}
