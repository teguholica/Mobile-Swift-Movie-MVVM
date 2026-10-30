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
            guard !suppressesQueryHandling else { return }
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
    private var discoverGeneration = 0
    private var hasRequestedGenres = false
    private var suppressesQueryHandling = false

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

    public var isTextMode: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public var activeFilterCount: Int {
        if isTextMode {
            return filters.searchYear == nil ? 0 : 1
        }

        var count = 0
        if filters.yearRange != nil { count += 1 }
        if filters.minRating != nil { count += 1 }
        if !filters.sort.isDefault { count += 1 }
        return count
    }

    public var hasFilterContext: Bool {
        isTextMode || hasDiscoveryContext
    }

    public var categorySummary: String {
        guard let first = selectedGenres.first else { return "Category" }
        guard selectedGenres.count > 1 else { return "Category: \(first.name)" }
        return "Category: \(first.name) +\(selectedGenres.count - 1)"
    }

    public var categoryAccessibilityLabel: String {
        guard !selectedGenres.isEmpty else { return "Category" }
        return "Category: \(selectedGenres.map(\.name).joined(separator: ", "))"
    }

    private var hasDiscoveryContext: Bool {
        !selectedGenres.isEmpty || filters.hasConstraints
    }

    private var isDiscoverRequest: Bool {
        if !selectedGenres.isEmpty { return true }
        guard !isTextMode else { return false }
        return filters.hasConstraints
    }

    public func onQueryChanged(_ newQuery: String) {
        searchTask?.cancel()

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if hasDiscoveryContext {
                // If query cleared but discovery context remains, re-fetch it
                discoverGeneration += 1
                let generation = discoverGeneration
                let filters = currentDiscoverFilters
                Task { @MainActor [weak self] in
                    await self?.executeDiscover(filters: filters, generation: generation)
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
        discoverGeneration += 1

        searchTask = Task { @MainActor in
            guard await self.waitForDebounce(debounceDuration) else { return }
            guard !Task.isCancelled else { return }

            state = .loading
            do {
                let results = try await searchMoviesUseCase.execute(
                    query: trimmed,
                    year: filters.searchYear,
                    page: 1
                )
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
    private func executeDiscover(
        filters: DiscoverFilters,
        generation: Int
    ) async {
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
    public func applyCategory(_ genreIds: [Int]) async {
        guard Set(genreIds) != Set(selectedGenres.map(\.id)) else { return }

        var draft = filters
        draft.genreIds = genreIds
        await applyFilters(draft)
    }

    @MainActor
    public func applyFilters(_ draft: DiscoverFilters) async {
        let mappedGenres = draft.genreIds.compactMap { id in
            genres.first(where: { $0.id == id })
                ?? Genre.popularPresets.first(where: { $0.id == id })
        }
        let selectsCategory = !mappedGenres.isEmpty

        if isTextMode && !selectsCategory {
            filters.searchYear = draft.searchYear
            await executeSearchImmediate(query: query)
            return
        }

        if selectsCategory {
            setQuery("")
        }
        selectedGenres = mappedGenres
        filters = DiscoverFilters(
            genreIds: mappedGenres.map(\.id),
            yearRange: draft.yearRange,
            minRating: draft.minRating,
            sort: draft.sort,
            searchYear: draft.searchYear
        )

        let request = currentDiscoverFilters
        guard hasDiscoveryContext else {
            discoverGeneration += 1
            resetResults()
            return
        }

        searchTask?.cancel()
        discoverGeneration += 1
        let generation = discoverGeneration
        state = .loading
        await executeDiscover(filters: request, generation: generation)
    }

    @MainActor
    public func resetAllFilters() async {
        searchTask?.cancel()
        discoverGeneration += 1

        selectedGenres = []
        filters = DiscoverFilters()
        setQuery("")

        resetResults()
        isLoadingMore = false
    }

    private func setQuery(_ newQuery: String) {
        suppressesQueryHandling = true
        query = newQuery
        suppressesQueryHandling = false
    }

    private func resetResults() {
        movies = []
        state = .initial
        page = 1
        canLoadMore = true
    }

    @MainActor
    public func refreshResults() async {
        if isDiscoverRequest {
            discoverGeneration += 1
            await executeDiscover(
                filters: currentDiscoverFilters,
                generation: discoverGeneration
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
                nextResults = try await searchMoviesUseCase.execute(
                    query: trimmed,
                    year: filters.searchYear,
                    page: nextPage
                )
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
        setQuery(query)
        self.selectedGenres = []
        filters = currentDiscoverFilters
        searchTask?.cancel()
        discoverGeneration += 1

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            if filters.hasConstraints {
                await executeDiscover(
                    filters: currentDiscoverFilters,
                    generation: discoverGeneration
                )
            } else {
                resetResults()
            }
            return
        }

        state = .loading
        do {
            let results = try await searchMoviesUseCase.execute(
                query: trimmed,
                year: filters.searchYear,
                page: 1
            )
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
