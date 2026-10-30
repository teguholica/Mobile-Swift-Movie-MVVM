//
//  MovieResultsGrid.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct MovieResultsGrid: View {
    let movies: [Movie]
    let isLoadingMore: Bool
    let onLoadMore: () -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
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

