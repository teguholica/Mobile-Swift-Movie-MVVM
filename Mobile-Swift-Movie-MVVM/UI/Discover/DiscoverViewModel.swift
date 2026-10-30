//
//  DiscoverViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class DiscoverViewModel {
    public enum State: Equatable {
        case loading
        case loaded
        case empty
        case error(String)
    }

    public var genres: [Genre] = Genre.popularPresets
    public var selectedGenres: [Genre] = []
    public private(set) var filters = DiscoverFilters()
    public var state: State = .loading
    public var movies: [Movie] = []
    public var page: Int = 1
    public var isLoadingMore: Bool = false
    public var canLoadMore: Bool = true
    public private(set) var resultsGeneration = 0

    private let discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol
    private let getGenresUseCase: GetGenresUseCaseProtocol
    private var requestGeneration = 0
    private var hasRequestedGenres = false
    private var hasLoadedInitial = false

    public init(
        discoverMoviesUseCase: DiscoverMoviesUseCaseProtocol,
        getGenresUseCase: GetGenresUseCaseProtocol
    ) {
        self.discoverMoviesUseCase = discoverMoviesUseCase
        self.getGenresUseCase = getGenresUseCase
    }

    public var activeFilterCount: Int {
        filters.activeFilterCount
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

    @MainActor
    public func loadInitial() async {
        guard !hasLoadedInitial else { return }
        hasLoadedInitial = true
        await loadFirstPage()
    }

    @MainActor
    public func refresh() async {
        await loadFirstPage(showLoading: false, resetsScroll: false)
    }

    @MainActor
    public func applyFilters(_ draft: DiscoverFilters) async {
        filters = DiscoverFilters(
            genreIds: selectedGenres.map(\.id),
            yearRange: draft.yearRange,
            minRating: draft.minRating,
            sort: draft.sort
        )
        await loadFirstPage()
    }

    @MainActor
    public func applyCategory(_ genreIds: [Int]) async {
        guard Set(genreIds) != Set(selectedGenres.map(\.id)) else { return }

        let mappedGenres = genreIds.compactMap { id in
            genres.first(where: { $0.id == id })
                ?? Genre.popularPresets.first(where: { $0.id == id })
        }
        selectedGenres = mappedGenres
        filters.genreIds = mappedGenres.map(\.id)
        await loadFirstPage()
    }

    @MainActor
    public func resetAll() async {
        selectedGenres = []
        filters = DiscoverFilters()
        await loadFirstPage()
    }

    @MainActor
    public func loadMore() async {
        guard !isLoadingMore && canLoadMore && !movies.isEmpty else { return }

        isLoadingMore = true
        let nextPage = page + 1
        let generation = requestGeneration

        do {
            let nextResults = try await discoverMoviesUseCase.execute(filters: filters, page: nextPage)
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

    @MainActor
    private func loadFirstPage(showLoading: Bool = true, resetsScroll: Bool = true) async {
        requestGeneration += 1
        let generation = requestGeneration
        if showLoading {
            state = .loading
        }

        do {
            let results = try await discoverMoviesUseCase.execute(filters: filters, page: 1)
            guard generation == requestGeneration else { return }

            movies = results
            page = 1
            canLoadMore = !results.isEmpty
            if resetsScroll {
                resultsGeneration += 1
            }
            state = results.isEmpty ? .empty : .loaded
        } catch {
            if Task.isCancelled {
                hasLoadedInitial = false
                return
            }
            guard generation == requestGeneration else { return }
            state = .error(error.localizedDescription)
        }
    }
}
