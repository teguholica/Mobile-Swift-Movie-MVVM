//
//  DiscoverView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct DiscoverView: View {
    private enum ActiveSheet: String, Identifiable {
        case filters
        case category

        var id: String { rawValue }
    }

    @State private var viewModel: DiscoverViewModel
    @State private var activeSheet: ActiveSheet?

    public init(viewModel: DiscoverViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                DiscoverFilterBar(
                    activeFilterCount: viewModel.activeFilterCount,
                    categorySummary: viewModel.categorySummary,
                    categoryAccessibilityLabel: viewModel.categoryAccessibilityLabel,
                    onFilter: { open(.filters) },
                    onCategory: { open(.category) }
                )

                Group {
                    switch viewModel.state {
                    case .loading:
                        LoadingView(message: "Loading discover...")
                    case .loaded:
                        MovieResultsGrid(
                            movies: viewModel.movies,
                            isLoadingMore: viewModel.isLoadingMore,
                            onLoadMore: {
                                Task {
                                    await viewModel.loadMore()
                                }
                            },
                            onRefresh: {
                                await viewModel.refresh()
                            }
                        )
                        .id(viewModel.resultsGeneration)
                    case .empty:
                        emptyResultsView
                    case .error(let message):
                        ErrorView(message: message) {
                            Task {
                                await viewModel.refresh()
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle("Discover")
            .appDestinations()
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .filters:
                    DiscoverFilterSheet(
                        filters: viewModel.filters,
                        isTextMode: false
                    ) { draft in
                        Task {
                            await viewModel.applyFilters(draft)
                        }
                    }
                case .category:
                    CategoryFilterSheet(
                        selectedGenreIds: viewModel.selectedGenres.map(\.id),
                        genres: viewModel.genres,
                        isTextMode: false
                    ) { genreIds in
                        Task {
                            await viewModel.applyCategory(genreIds)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadInitial()
            }
        }
    }

    private var emptyResultsView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CinemaTokens.Colors.elevated)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5))

                Image(systemName: "film.stack")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CinemaTokens.Colors.gold)
            }

            VStack(spacing: 6) {
                Text("No Movies Found")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)

                Text("Try different filters or categories.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Clear filters & category") {
                Task {
                    await viewModel.resetAll()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(CinemaTokens.Colors.gold)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .accessibilityLabel("Clear filters and category")
        }
        .padding(.vertical, 40)
    }

    private func open(_ sheet: ActiveSheet) {
        Task {
            await viewModel.loadGenres()
        }
        activeSheet = sheet
    }
}

#if DEBUG
#Preview {
    DiscoverView(viewModel: AppContainer.preview.makeDiscoverViewModel())
        .environment(AppContainer.preview)
}
#endif
