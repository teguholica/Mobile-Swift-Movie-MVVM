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

    public var genres: [Genre] = Genre.popularPresets
    public var selectedGenres: [Genre] = []
    public private(set) var filters = DiscoverFilters()
    public var state: State = .initial
    public var movies: [Movie] = []
    public var page: Int = 1
    public var isLoadingMore: Bool = false
    public var canLoadMore: Bool = true
    public private(set) var resultsGeneration = 0

    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private let discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol?
    private let getGenresUseCase: GetGenresUseCaseProtocol
    private let debounceDuration: Duration
    private var searchTask: Task<Void, Never>?
    private var genreFetchTask: Task<Void, Never>?
    private var discoverGeneration = 0
    private var hasRequestedGenres = false

    public init(
        searchMoviesUseCase: SearchMoviesUseCaseProtocol,
        discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol? = nil,
        getGenresUseCase: GetGenresUseCaseProtocol,
        debounceDuration: Duration = .milliseconds(500)
    ) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.discoverMoviesUseCase = discoverMoviesUseCase
        self.getGenresUseCase = getGenresUseCase
        self.debounceDuration = debounceDuration
    }

    @MainActor
    public func loadGenres() async {
        guard !hasRequestedGenres else { return }
        hasRequestedGenres = true

        do {
            let catalogue = try await getGenresUseCase.execute()
            guard !catalogue.isEmpty else { return }

            genres = catalogue
            selectedGenres = selectedGenres.map { selected in
                catalogue.first(where: { $0.id == selected.id }) ?? selected
            }
        } catch {
            if Task.isCancelled {
                hasRequestedGenres = false
            }
        }
    }

    public var currentDiscoverFilters: DiscoverFilters {
        DiscoverFilters(
            genreIds: selectedGenres.map(\.id),
            yearRange: filters.yearRange,
            minRating: filters.minRating,
            sort: filters.sort,
            searchYear: filters.searchYear
        )
    }

    public var activeFilterCount: Int {
        if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return filters.searchYear == nil ? 0 : 1
        }

        var count = 0
        if filters.yearRange != nil { count += 1 }
        if filters.minRating != nil { count += 1 }
        if !filters.sort.isDefault { count += 1 }
        return count
    }

    public var hasVisibleDiscoverFilters: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (filters.yearRange != nil || filters.minRating != nil || !filters.sort.isDefault)
    }

    private var isDiscoverRequest: Bool {
        if !selectedGenres.isEmpty { return true }
        guard query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        return filters.yearRange != nil || filters.minRating != nil || !filters.sort.isDefault
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
        filters = currentDiscoverFilters
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
                self.resultsGeneration += 1

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
        filters = currentDiscoverFilters

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
            self.resultsGeneration += 1
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
    public func applyFilters(_ draft: DiscoverFilters) async {
        filters = DiscoverFilters(
            genreIds: selectedGenres.map(\.id),
            yearRange: draft.yearRange,
            minRating: draft.minRating,
            sort: draft.sort,
            searchYear: draft.searchYear
        )

        let request = currentDiscoverFilters
        guard !selectedGenres.isEmpty || request != DiscoverFilters() else {
            movies = []
            state = .initial
            page = 1
            canLoadMore = true
            return
        }

        genreFetchTask?.cancel()
        searchTask?.cancel()
        discoverGeneration += 1
        let generation = discoverGeneration
        state = .loading
        await executeDiscover(filters: request, generation: generation, debounce: .zero)
    }

    @MainActor
    public func clearYearRange() async {
        await clearing { $0.yearRange = nil }
    }

    @MainActor
    public func clearMinRating() async {
        await clearing { $0.minRating = nil }
    }

    @MainActor
    public func clearSort() async {
        await clearing { $0.sort = .popularity }
    }

    @MainActor
    private func clearing(_ mutate: (inout DiscoverFilters) -> Void) async {
        var updated = filters
        mutate(&updated)
        await applyFilters(updated)
    }

    @MainActor
    public func refreshResults() async {
        if isDiscoverRequest {
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
            if isDiscoverRequest, let discoverMoviesUseCase {
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
        filters = currentDiscoverFilters
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
            self.resultsGeneration += 1
            self.state = results.isEmpty ? .empty : .loaded
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }
}
