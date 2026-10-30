//
//  PersonCreditRowView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct PersonCreditRowView: View {
    public let credit: PersonMovieCredit

    public init(credit: PersonMovieCredit) {
        self.credit = credit
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            TMDBImageView(path: credit.posterPath, size: "w342")
                .frame(width: 84, height: 126)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(credit.title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
                    .lineLimit(2)

                if let year = credit.releaseYear {
                    Text(year)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)
                }

                Text("as \(characterName)")
                    .font(.caption)
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
                    .lineLimit(2)
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var characterName: String {
        credit.character.isEmpty ? "—" : credit.character
    }

    private var accessibilityLabel: String {
        let year = credit.releaseYear ?? "unknown year"
        guard !credit.character.isEmpty else {
            return "\(credit.title), \(year)"
        }
        return "\(credit.title), \(year), as \(credit.character)"
    }
}
