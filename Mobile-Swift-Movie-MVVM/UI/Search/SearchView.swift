//
//  SearchView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    private let selectableYears: [Int]

    public init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
        let currentYear = Calendar.current.component(.year, from: Date())
        selectableYears = Array((1950...currentYear).reversed())
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                yearBar

                Group {
                    switch viewModel.state {
                    case .initial:
                        initialSearchView
                    case .loading:
                        LoadingView(message: "Searching cinema database...")
                    case .empty:
                        emptyResultsView
                    case .error(let message):
                        ErrorView(message: message) {
                            Task {
                                await viewModel.retry()
                            }
                        }
                    case .loaded:
                        resultsGrid
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle("Search")
            .appDestinations()
            .searchable(
                text: $viewModel.query,
                prompt: "Search movies by title..."
            )
        }
    }

    private var yearBar: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))

                Text("Year")
                    .font(.caption.weight(.semibold))

                Picker("", selection: yearSelection) {
                    Text("Any").tag(Int?.none)
                    ForEach(selectableYears, id: \.self) { year in
                        Text(String(year)).tag(Int?.some(year))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .tint(CinemaTokens.Colors.textPrimary)
            }
            .foregroundStyle(CinemaTokens.Colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(CinemaTokens.Colors.elevated)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Release year")
            .accessibilityValue(viewModel.selectedYear.map(String.init) ?? "Any")

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var yearSelection: Binding<Int?> {
        Binding(
            get: { viewModel.selectedYear },
            set: { year in
                Task {
                    await viewModel.applyYear(year)
                }
            }
        )
    }

    private var resultsGrid: some View {
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
    }

    private var initialSearchView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CinemaTokens.Colors.elevated)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5))

                Image(systemName: "magnifyingglass")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CinemaTokens.Colors.gold)
            }

            VStack(spacing: 6) {
                Text("Search Movies")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)

                Text("Search by title, with an optional release year.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 40)
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

                Text("Try a different title or clear the year filter.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Clear search & year") {
                Task {
                    await viewModel.reset()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(CinemaTokens.Colors.gold)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .accessibilityLabel("Clear search and year")
        }
        .padding(.vertical, 40)
    }
}

#if DEBUG
#Preview {
    SearchView(viewModel: AppContainer.preview.makeSearchViewModel())
}
#endif
