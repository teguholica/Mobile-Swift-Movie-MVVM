//
//  HomeView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct HomeView: View {
    @State private var viewModel: HomeViewModel
    public var onSelectMovie: ((Movie) -> Void)?

    public init(
        viewModel: HomeViewModel,
        onSelectMovie: ((Movie) -> Void)? = nil
    ) {
        _viewModel = State(initialValue: viewModel)
        self.onSelectMovie = onSelectMovie
    }

    public var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle, .loading:
                    if viewModel.nowPlayingMovies.isEmpty && viewModel.popularMovies.isEmpty {
                        LoadingView(message: "Loading movies...")
                    } else {
                        contentView
                    }
                case .error(let message):
                    if viewModel.nowPlayingMovies.isEmpty && viewModel.popularMovies.isEmpty {
                        ErrorView(message: message) {
                            Task {
                                await viewModel.fetchHomeData()
                            }
                        }
                    } else {
                        contentView
                    }
                case .loaded:
                    contentView
                }
            }
            .navigationTitle("Movie DB")
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .appDestinations()
            .task {
                await viewModel.fetchHomeData()
            }
            .refreshable {
                await viewModel.fetchHomeData()
            }
        }
    }

    private var contentView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 28) {
                // 1. Now Playing Carousel
                if !viewModel.nowPlayingMovies.isEmpty {
                    NowPlayingCarouselView(
                        movies: viewModel.nowPlayingMovies,
                        isFavorite: { movie in viewModel.isFavorite(movieId: movie.id) },
                        onToggleFavorite: { movie in
                            Task {
                                await viewModel.toggleFavorite(movie: movie)
                            }
                        },
                        onSelectMovie: onSelectMovie
                    )
                }

                // 2. Top Rated Carousel
                if !viewModel.topRatedMovies.isEmpty {
                    TopRatedCarouselView(
                        movies: viewModel.topRatedMovies,
                        onSelectMovie: onSelectMovie
                    )
                }

                // 3. Popular Movies List with Infinite Scrolling
                if !viewModel.popularMovies.isEmpty {
                    popularSection
                }
            }
            .padding(.vertical)
        }
    }

    private var popularSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("THE BOX OFFICE")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.crimson)

                Text("Popular Movies")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }
            .padding(.horizontal)

            LazyVStack(spacing: 12) {
                ForEach(viewModel.popularMovies) { movie in
                    MovieRowView(movie: movie) {
                        onSelectMovie?(movie)
                    }
                    .padding(.horizontal)
                    .onAppear {
                        // Trigger pagination when reaching 3 items before the end
                        if movie.id == viewModel.popularMovies.suffix(3).first?.id {
                            Task {
                                await viewModel.loadMorePopularMovies()
                            }
                        }
                    }
                }

                if viewModel.isLoadingMorePopular {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Loading more movies...")
                            .font(.caption)
                            .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }

                if let error = viewModel.paginationError {
                    VStack(spacing: 6) {
                        Text("Failed to load: \(error)")
                            .font(.caption)
                            .foregroundStyle(.red)

                        Button {
                            Task {
                                await viewModel.retryLoadMorePopular()
                            }
                        } label: {
                            Text("Retry")
                                .font(.caption.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    HomeView(viewModel: AppContainer.preview.makeHomeViewModel())
}
#endif
