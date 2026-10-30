//
//  TopRatedCarouselView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct TopRatedCarouselView: View {
    public let movies: [Movie]

    public init(movies: [Movie]) {
        self.movies = movies
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with cinematic kicker
            VStack(alignment: .leading, spacing: 2) {
                Text("HALL OF FAME")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.gold)

                Text("Top Rated")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                        NavigationLink(value: AppRoute.movie(id: movie.id)) {
                            topRatedCard(for: movie, rank: index + 1)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private func topRatedCard(for movie: Movie, rank: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottomLeading) {
                // Poster
                TMDBImageView(path: movie.posterPath, size: "w500")
                    .frame(width: 136, height: 204)
                    .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                            .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                    )

                // Progressive subtle gradient behind watermark
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.5),
                        .init(color: .black.opacity(0.85), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))

                // Watermark rank badge anchored to bottom leading
                HStack(spacing: 2) {
                    Text(String(format: "#%02d", rank))
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundStyle(rank <= 3 ? CinemaTokens.Colors.gold : .white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: CinemaTokens.Radius.card,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 8
                    )
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: CinemaTokens.Radius.card,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 8
                    )
                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                )
            }
            .frame(width: 136, height: 204)

            // Movie meta info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    RatingBadgeView(rating: movie.voteAverage)

                    if let year = movie.releaseDate?.prefix(4), !year.isEmpty {
                        Text(String(year))
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(CinemaTokens.Colors.textMuted)
                    }
                }
            }
            .frame(width: 136, alignment: .leading)
        }
    }
}
