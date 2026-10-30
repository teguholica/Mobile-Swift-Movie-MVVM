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

    public var selectedYear: Int?
    public var state: State = .initial
    public var movies: [Movie] = []
    public var page: Int = 1
    public var isLoadingMore: Bool = false
    public var canLoadMore: Bool = true
    public private(set) var resultsGeneration = 0

    private let searchMoviesUseCase: SearchMoviesUseCaseProtocol
    private let debounceDuration: Duration
    private var searchTask: Task<Void, Never>?
    private var suppressesQueryHandling = false
    private var requestGeneration = 0

    public init(
        searchMoviesUseCase: SearchMoviesUseCaseProtocol,
        debounceDuration: Duration = .milliseconds(500)
    ) {
        self.searchMoviesUseCase = searchMoviesUseCase
        self.debounceDuration = debounceDuration
    }

    public func onQueryChanged(_ newQuery: String) {
        searchTask?.cancel()

        let trimmed = newQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetResults()
            return
        }

        let year = selectedYear
        searchTask = Task { @MainActor [weak self] in
            guard let self else { return }
            guard await self.waitForDebounce() else { return }
            guard !Task.isCancelled else { return }
            await self.performSearch(query: trimmed, year: year)
        }
    }

    @MainActor
    public func applyYear(_ year: Int?) async {
        selectedYear = year

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        await executeSearchImmediate(query: query)
    }

    @MainActor
    public func executeSearchImmediate(query: String) async {
        setQuery(query)
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetResults()
            return
        }

        await performSearch(query: trimmed, year: selectedYear)
    }

    @MainActor
    public func refresh() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetResults()
            return
        }

        await performSearch(query: trimmed, year: selectedYear, showLoading: false, resetsScroll: false)
    }

    @MainActor
    public func retry() async {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            resetResults()
            return
        }

        await performSearch(query: trimmed, year: selectedYear)
    }

    @MainActor
    public func reset() async {
        searchTask?.cancel()
        setQuery("")
        selectedYear = nil
        resetResults()
    }

    @MainActor
    public func loadMore() async {
        guard !isLoadingMore && canLoadMore && !movies.isEmpty else { return }

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoadingMore = true
        let nextPage = page + 1
        let generation = requestGeneration

        do {
            let nextResults = try await searchMoviesUseCase.execute(
                query: trimmed,
                year: selectedYear,
                page: nextPage
            )
            guard generation == requestGeneration else {
                isLoadingMore = false
                return
            }

            if nextResults.isEmpty {
                canLoadMore = false
            } else {
                let existingIds = Set(movies.map(\.id))
                let newUnique = nextResults.filter { !existingIds.contains($0.id) }
                movies.append(contentsOf: newUnique)
                page = nextPage
            }
        } catch {
            // Keep existing results intact on pagination error.
        }

        isLoadingMore = false
    }

    @MainActor
    private func performSearch(
        query: String,
        year: Int?,
        showLoading: Bool = true,
        resetsScroll: Bool = true
    ) async {
        requestGeneration += 1
        let generation = requestGeneration
        if showLoading {
            state = .loading
        }

        do {
            let results = try await searchMoviesUseCase.execute(query: query, year: year, page: 1)
            guard !Task.isCancelled, generation == requestGeneration else { return }

            movies = results
            page = 1
            canLoadMore = !results.isEmpty
            if resetsScroll {
                resultsGeneration += 1
            }
            state = results.isEmpty ? .empty : .loaded
        } catch {
            guard !Task.isCancelled, generation == requestGeneration else { return }
            state = .error(error.localizedDescription)
        }
    }

    private func waitForDebounce() async -> Bool {
        do {
            if debounceDuration > .zero {
                try await Task.sleep(for: debounceDuration)
            }
            return true
        } catch {
            return false
        }
    }

    private func setQuery(_ newQuery: String) {
        suppressesQueryHandling = true
        query = newQuery
        suppressesQueryHandling = false
    }

    private func resetResults() {
        requestGeneration += 1
        movies = []
        state = .initial
        page = 1
        canLoadMore = true
        isLoadingMore = false
    }
}
