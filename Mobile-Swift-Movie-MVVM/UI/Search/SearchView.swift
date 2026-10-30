//
//  SearchView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct SearchView: View {
    private enum ActiveSheet: String, Identifiable {
        case filters
        case category

        var id: String { rawValue }
    }

    @State private var viewModel: SearchViewModel
    @State private var activeSheet: ActiveSheet?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public init(viewModel: SearchViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if viewModel.hasFilterContext {
                    filterBar
                }

                // Content Area
                Group {
                    switch viewModel.state {
                    case .initial:
                        initialDiscoveryView
                    case .loading:
                        LoadingView(message: "Searching cinema database...")
                    case .empty:
                        emptyResultsView
                    case .error(let message):
                        ErrorView(message: message) {
                            Task {
                                await viewModel.refreshResults()
                            }
                        }
                    case .loaded:
                        resultsGridView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle("Search & Discover")
            .appDestinations()
            .searchable(
                text: $viewModel.query,
                prompt: "Search movies by title..."
            )
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .filters:
                    DiscoverFilterSheet(
                        filters: viewModel.currentDiscoverFilters,
                        isTextMode: viewModel.isTextMode
                    ) { draft in
                        Task {
                            await viewModel.applyFilters(draft)
                        }
                    }
                case .category:
                    CategoryFilterSheet(
                        selectedGenreIds: viewModel.selectedGenres.map(\.id),
                        genres: viewModel.genres,
                        isTextMode: viewModel.isTextMode
                    ) { genreIds in
                        Task {
                            await viewModel.applyCategory(genreIds)
                        }
                    }
                }
            }
        }
    }

    private var filterBar: some View {
        let count = viewModel.activeFilterCount

        return HStack {
            Button {
                open(.filters)
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Filter")
                        .font(.caption.weight(.semibold))

                    if count > 0 {
                        Text("· \(count)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CinemaTokens.Colors.gold)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
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
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filter")
            .accessibilityValue(count == 0 ? "No filters" : "\(count) filters")

            Button {
                open(.category)
            } label: {
                HStack(spacing: 5) {
                    Text(viewModel.categorySummary)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
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
            }
            .buttonStyle(.plain)
            .accessibilityLabel(viewModel.categoryAccessibilityLabel)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func open(_ sheet: ActiveSheet) {
        Task {
            await viewModel.loadGenres()
        }
        activeSheet = sheet
    }

    private var resultsGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.movies) { movie in
                    NavigationLink(value: AppRoute.movie(id: movie.id)) {
                        moviePosterCard(for: movie)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if movie.id == viewModel.movies.suffix(4).first?.id {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if viewModel.isLoadingMore {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading more titles...")
                        .font(.caption)
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
            }
        }
        .id(viewModel.resultsGeneration)
    }

    private func moviePosterCard(for movie: Movie) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                TMDBImageView(path: movie.posterPath, size: "w500")
                    .frame(maxWidth: .infinity)
                    .aspectRatio(2/3, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                            .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                    )

                RatingBadgeView(rating: movie.voteAverage)
                    .padding(8)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(movie.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
                    .lineLimit(1)

                if let date = movie.releaseDate, !date.isEmpty {
                    Text(String(date.prefix(4)))
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(CinemaTokens.Colors.textMuted)
                }
            }
        }
    }

    private var initialDiscoveryView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CinemaTokens.Colors.elevated)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5))

                Image(systemName: "sparkles.tv")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CinemaTokens.Colors.crimson)
            }

            VStack(spacing: 6) {
                Text("Discover Cinema")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)

                Text("Search by title, or browse by filters.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Browse by filters") {
                open(.filters)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(CinemaTokens.Colors.gold)
            .buttonStyle(.plain)
            .accessibilityLabel("Browse by filters")
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

                Text("Try searching with different keywords like 'Inception', 'Batman', or adjust your filters.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Button("Clear search & filters") {
                Task {
                    await viewModel.resetAllFilters()
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
            .background(CinemaTokens.Colors.gold)
            .clipShape(Capsule())
            .buttonStyle(.plain)
            .accessibilityLabel("Clear search and filters")
        }
        .padding(.vertical, 40)
    }
}

#if DEBUG
#Preview {
    SearchView(viewModel: AppContainer.preview.makeSearchViewModel())
}
#endif
