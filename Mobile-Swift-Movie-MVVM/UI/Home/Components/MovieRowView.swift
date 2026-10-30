//
//  MovieRowView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct MovieRowView: View {
    public let movie: Movie
    public var onSelect: (() -> Void)?

    public init(movie: Movie, onSelect: (() -> Void)? = nil) {
        self.movie = movie
        self.onSelect = onSelect
    }

    public var body: some View {
        NavigationLink(value: AppRoute.movie(id: movie.id)) {
            HStack(alignment: .center, spacing: 14) {
                // 84x126 poster with 12pt corner radius and 0.5pt glass border
                TMDBImageView(path: movie.posterPath, size: "w500")
                    .frame(width: 84, height: 126)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                    )

                // Movie details
                VStack(alignment: .leading, spacing: 8) {
                    Text(movie.title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(CinemaTokens.Colors.textPrimary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        RatingBadgeView(rating: movie.voteAverage)

                        if let date = movie.releaseDate, !date.isEmpty {
                            Text(String(date.prefix(4)))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(CinemaTokens.Colors.textSecondary)
                        }
                    }

                    if !movie.overview.isEmpty {
                        Text(movie.overview)
                            .font(.caption)
                            .foregroundStyle(CinemaTokens.Colors.textMuted)
                            .lineLimit(2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
                    .padding(.trailing, 4)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(CinemaTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded {
            onSelect?()
        })
    }
}
