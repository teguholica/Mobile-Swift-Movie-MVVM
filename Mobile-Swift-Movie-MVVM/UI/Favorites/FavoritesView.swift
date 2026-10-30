//
//  FavoritesView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct FavoritesView: View {
    public enum ViewMode: String, CaseIterable {
        case grid
        case list
    }

    @State private var viewModel: FavoritesViewModel
    @State private var viewMode: ViewMode = .grid

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    public init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                Group {
                    if viewModel.isLoading && viewModel.favorites.isEmpty {
                        LoadingView(message: "Loading your favorites...")
                    } else if viewModel.visibleFavorites.isEmpty {
                        emptyWatchlistView
                    } else {
                        contentView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Floating 4-second Undo Toast
                if viewModel.toastMovie != nil {
                    undoToast
                }
            }
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewMode = viewMode == .grid ? .list : .grid
                        }
                    } label: {
                        Image(systemName: viewMode == .grid ? "list.bullet" : "square.grid.2x2")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(CinemaTokens.Colors.textPrimary)
                    }
                    .accessibilityLabel("Toggle layout mode")
                }
            }
            .appDestinations(onFavoriteChanged: {
                Task {
                    await viewModel.fetchFavorites()
                }
            })
            .task {
                await viewModel.fetchFavorites()
            }
            .refreshable {
                await viewModel.fetchFavorites()
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewMode == .grid {
            posterGridView
        } else {
            detailedListView
        }
    }

    private var posterGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.visibleFavorites) { movie in
                    NavigationLink(value: AppRoute.movie(id: movie.id)) {
                        gridPosterCard(for: movie)
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.visibleFavorites)
        }
    }

    private func gridPosterCard(for movie: Movie) -> some View {
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

                HStack {
                    RatingBadgeView(rating: movie.voteAverage)

                    Spacer()

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            viewModel.stageRemoval(movie: movie)
                        }
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(CinemaTokens.Colors.gold)
                            .frame(width: 30, height: 30)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove \(movie.title) from favorites")
                }
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 2) {
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

    private var detailedListView: some View {
        List {
            ForEach(viewModel.visibleFavorites) { movie in
                MovieRowView(movie: movie)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
            }
            .onDelete { offsets in
                Task {
                    await viewModel.removeFavorites(at: offsets)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyWatchlistView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CinemaTokens.Colors.elevated)
                    .frame(width: 80, height: 80)
                    .overlay(Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5))

                Image(systemName: "ticket")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(CinemaTokens.Colors.gold)
            }

            VStack(spacing: 6) {
                Text("Your Watchlist is Empty")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)

                Text("Bookmark premier releases and top rated films to build your personal cinema collection.")
                    .font(.subheadline)
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
        .padding(.vertical, 40)
    }

    private var undoToast: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash.slash")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(CinemaTokens.Colors.gold)

            Text("Removed from Favorites")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)

            Spacer()

            Button("Undo") {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                    viewModel.undoRemoval()
                }
            }
            .font(.subheadline.weight(.bold))
            .foregroundStyle(CinemaTokens.Colors.gold)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(CinemaTokens.Colors.elevated)
        .clipShape(Capsule())
        .overlay(
            Capsule().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

#if DEBUG
#Preview {
    FavoritesView(viewModel: AppContainer.preview.makeFavoritesViewModel())
}
#endif
