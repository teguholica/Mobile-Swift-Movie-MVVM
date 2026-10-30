//
//  MovieResultsGrid.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct MovieResultsGrid: View {
    let movies: [Movie]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void
    let onRefresh: (() async -> Void)?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(
        movies: [Movie],
        isLoadingMore: Bool,
        onLoadMore: @escaping () -> Void,
        onRefresh: (() async -> Void)? = nil
    ) {
        self.movies = movies
        self.isLoadingMore = isLoadingMore
        self.onLoadMore = onLoadMore
        self.onRefresh = onRefresh
    }

    var body: some View {
        if let onRefresh {
            scrollView
                .refreshable {
                    await onRefresh()
                }
        } else {
            scrollView
        }
    }

    private var scrollView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(movies) { movie in
                    NavigationLink(value: AppRoute.movie(id: movie.id)) {
                        MoviePosterCard(movie: movie)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        if movie.id == movies.suffix(4).first?.id {
                            onLoadMore()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if isLoadingMore {
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
}
