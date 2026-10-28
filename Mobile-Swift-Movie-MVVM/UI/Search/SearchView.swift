//
//  SearchView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct SearchView: View {
    @State private var viewModel: SearchViewModel
    public var onSelectMovie: ((Movie) -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public init(
        viewModel: SearchViewModel? = nil,
        onSelectMovie: ((Movie) -> Void)? = nil
    ) {
        if let viewModel = viewModel {
            _viewModel = State(initialValue: viewModel)
        } else {
            let repository = MovieRepositoryImpl()
            let searchUseCase = SearchMoviesUseCase(repository: repository)
            let discoverUseCase = DiscoverMoviesByGenreUseCase(repository: repository)
            _viewModel = State(
                initialValue: SearchViewModel(
                    searchMoviesUseCase: searchUseCase,
                    discoverMoviesByGenreUseCase: discoverUseCase
                )
            )
        }
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Horizontal Genre Chips
                genreChipsBar

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
                                if let genre = viewModel.selectedGenre {
                                    await viewModel.selectGenre(genre)
                                } else {
                                    await viewModel.executeSearchImmediate(query: viewModel.query)
                                }
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
            .navigationDestination(for: Movie.self) { movie in
                MovieDetailView(movieId: movie.id)
            }
            .searchable(
                text: $viewModel.query,
                prompt: "Search movies by title..."
            )
        }
    }

    private var genreChipsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Genre.popularPresets) { genre in
                    let isSelected = viewModel.selectedGenre?.id == genre.id
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        Task {
                            await viewModel.selectGenre(genre)
                        }
                    } label: {
                        Text(genre.name)
                            .font(.caption.weight(isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .black : CinemaTokens.Colors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(isSelected ? CinemaTokens.Colors.gold : CinemaTokens.Colors.elevated)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? Color.clear : CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(CinemaTokens.Colors.surface.opacity(0.6))
    }

    private var resultsGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.movies) { movie in
                    NavigationLink(value: movie) {
                        moviePosterCard(for: movie)
                    }
                    .buttonStyle(.plain)
                    .simultaneousGesture(TapGesture().onEnded {
                        onSelectMovie?(movie)
                    })
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

                Text("Explore theatrical releases by title or tap any genre pill above.")
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

                Text("Try searching with different keywords like 'Inception', 'Batman', or pick a genre above.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    SearchView()
}
