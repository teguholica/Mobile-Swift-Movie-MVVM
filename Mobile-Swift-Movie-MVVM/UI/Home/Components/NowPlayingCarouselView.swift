//
//  NowPlayingCarouselView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct NowPlayingCarouselView: View {
    public let movies: [Movie]
    public var isFavorite: ((Movie) -> Bool)?
    public var onToggleFavorite: ((Movie) -> Void)?
    public var onSelectMovie: ((Movie) -> Void)?

    @State private var scrolledID: Int?

    public init(
        movies: [Movie],
        isFavorite: ((Movie) -> Bool)? = nil,
        onToggleFavorite: ((Movie) -> Void)? = nil,
        onSelectMovie: ((Movie) -> Void)? = nil
    ) {
        self.movies = movies
        self.isFavorite = isFavorite
        self.onToggleFavorite = onToggleFavorite
        self.onSelectMovie = onSelectMovie
    }

    private var activeIndex: Int {
        guard let scrolledID, let index = movies.firstIndex(where: { $0.id == scrolledID }) else {
            return 0
        }
        return index
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with cinematic kicker
            VStack(alignment: .leading, spacing: 2) {
                Text("SPOTLIGHT")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.accent)

                Text("Now Playing")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }
            .padding(.horizontal)

            // 16:10 Widescreen Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(movies) { movie in
                        spotlightCard(for: movie)
                            .id(movie.id)
                            .scrollTransition(.interactive, axis: .horizontal) { content, phase in
                                content
                                    .scaleEffect(phase.isIdentity ? 1.0 : 0.88)
                                    .opacity(phase.isIdentity ? 1.0 : 0.80)
                            }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .safeAreaPadding(.horizontal, 24)
            .scrollPosition(id: $scrolledID)
            .onAppear {
                if scrolledID == nil, let first = movies.first {
                    scrolledID = first.id
                }
            }

            // Discreet page indicator
            if movies.count > 1 {
                pageIndicator
                    .frame(maxWidth: .infinity)
                    .padding(.top, 2)
            }
        }
    }

    private func spotlightCard(for movie: Movie) -> some View {
        ZStack(alignment: .bottomLeading) {
            // Backdrop with fallback to poster
            TMDBImageView(
                path: movie.backdropPath ?? movie.posterPath,
                size: "w780",
                contentMode: .fill
            )
            .frame(width: 320, height: 200)
            .clipped()

            // Progressive vertical gradient overlay
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: .black.opacity(0.2), location: 0.3),
                    .init(color: .black.opacity(0.75), location: 0.72),
                    .init(color: .black.opacity(0.92), location: 1.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Top overlay: rating badge and bookmark button
            VStack {
                HStack(spacing: 8) {
                    Spacer()

                    RatingBadgeView(rating: movie.voteAverage)

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onToggleFavorite?(movie)
                    } label: {
                        let favorited = isFavorite?(movie) ?? false
                        Image(systemName: favorited ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(favorited ? CinemaTokens.Colors.accent : .white)
                            .frame(width: 32, height: 32)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Bookmark \(movie.title)")
                }
                .padding(12)

                Spacer()
            }

            // Bottom overlay: title, release year, view details
            VStack(alignment: .leading, spacing: 6) {
                if let releaseDate = movie.releaseDate, !releaseDate.isEmpty {
                    Text(String(releaseDate.prefix(4)))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CinemaTokens.Colors.accent)
                }

                Text(movie.title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)

                HStack {
                    NavigationLink(value: movie) {
                        HStack(spacing: 5) {
                            Text("View Details")
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(CinemaTokens.Colors.primary)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.top, 2)
            }
            .padding(14)
        }
        .frame(width: 320, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.CornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: CinemaTokens.CornerRadius.large)
                .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    private var pageIndicator: some View {
        let maxDots = min(movies.count, 7)
        let displayIndex = min(activeIndex, maxDots - 1)

        return HStack(spacing: 6) {
            ForEach(0..<maxDots, id: \.self) { index in
                Capsule()
                    .fill(index == displayIndex ? CinemaTokens.Colors.accent : Color.secondary.opacity(0.35))
                    .frame(width: index == displayIndex ? 18 : 6, height: 5)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: displayIndex)
            }
        }
    }
}
