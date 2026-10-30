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

    public var selectedGenres: [Genre] = []
    public var state: State = .initial
    public var movies: [Movie] = []
    public var page: Int = 1
    public var isLoadingMore: Bool = false
    public var canLoadMore: Bool = true

    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private let discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol?
    private let debounceDuration: Duration
    private var searchTask: Task<Void, Never>?
    private var genreFetchTask: Task<Void, Never>?
    private var discoverGeneration = 0

    public init(
        searchMoviesUseCase: SearchMoviesUseCaseProtocol,
        discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol? = nil,
        debounceDuration: Duration = .milliseconds(500)
    ) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.discoverMoviesUseCase = discoverMoviesUseCase
        self.debounceDuration = debounceDuration
    }

    public var currentDiscoverFilters: DiscoverFilters {
        DiscoverFilters(genreIds: selectedGenres.map(\.id))
    }

    public func isSelected(_ genre: Genre) -> Bool {
        selectedGenres.contains { $0.id == genre.id }
    }

    public func onQueryChanged(_ newQuery: String) {
        searchTask?.cancel()

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if !selectedGenres.isEmpty {
                // If query cleared but genres are selected, re-fetch discovery
                discoverGeneration += 1
                let generation = discoverGeneration
                let filters = currentDiscoverFilters
                Task { @MainActor [weak self] in
                    await self?.executeDiscover(filters: filters, generation: generation, debounce: .zero)
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
        selectedGenres = []
        genreFetchTask?.cancel()
        discoverGeneration += 1

        searchTask = Task { @MainActor in
            guard await self.waitForDebounce(debounceDuration) else { return }
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
    public func toggleGenre(_ genre: Genre) async {
        genreFetchTask?.cancel()
        searchTask?.cancel()

        if isSelected(genre) {
            selectedGenres.removeAll { $0.id == genre.id }
        } else {
            if !query.isEmpty {
                query = ""
            }
            selectedGenres.append(genre)
        }

        guard !selectedGenres.isEmpty else {
            movies = []
            state = .initial
            page = 1
            canLoadMore = true
            return
        }

        discoverGeneration += 1
        let generation = discoverGeneration
        let filters = currentDiscoverFilters
        state = .loading

        let debounceDuration = self.debounceDuration
        let task = Task { @MainActor [weak self] in
            guard let self else { return }
            await self.executeDiscover(
                filters: filters,
                generation: generation,
                debounce: debounceDuration
            )
        }
        genreFetchTask = task
        await task.value
    }

    @MainActor
    private func executeDiscover(
        filters: DiscoverFilters,
        generation: Int,
        debounce: Duration
    ) async {
        guard await waitForDebounce(debounce) else { return }
        guard generation == discoverGeneration else { return }
        guard let discoverMoviesUseCase else {
            state = .empty
            return
        }

        do {
            let results = try await discoverMoviesUseCase.execute(filters: filters, page: 1)
            guard generation == discoverGeneration else { return }
            self.movies = results
            self.page = 1
            self.canLoadMore = !results.isEmpty
            self.state = results.isEmpty ? .empty : .loaded
        } catch {
            guard generation == discoverGeneration else { return }
            self.state = .error(error.localizedDescription)
        }
    }

    private func waitForDebounce(_ duration: Duration) async -> Bool {
        do {
            if duration > .zero {
                try await Task.sleep(for: duration)
            }
            return true
        } catch {
            return false
        }
    }

    @MainActor
    public func refreshResults() async {
        if !selectedGenres.isEmpty {
            discoverGeneration += 1
            await executeDiscover(
                filters: currentDiscoverFilters,
                generation: discoverGeneration,
                debounce: .zero
            )
        } else {
            await executeSearchImmediate(query: query)
        }
    }

    @MainActor
    public func loadMore() async {
        guard !isLoadingMore && canLoadMore && !movies.isEmpty else { return }

        isLoadingMore = true
        let nextPage = page + 1
        let requestGeneration = discoverGeneration

        do {
            let nextResults: [Movie]
            if !selectedGenres.isEmpty, let discoverMoviesUseCase {
                nextResults = try await discoverMoviesUseCase.execute(
                    filters: currentDiscoverFilters,
                    page: nextPage
                )
            } else {
                let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else {
                    isLoadingMore = false
                    return
                }
                nextResults = try await searchMoviesUseCase.execute(query: trimmed, page: nextPage)
            }

            guard requestGeneration == discoverGeneration else {
                isLoadingMore = false
                return
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
        self.selectedGenres = []
        searchTask?.cancel()
        genreFetchTask?.cancel()
        discoverGeneration += 1

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
