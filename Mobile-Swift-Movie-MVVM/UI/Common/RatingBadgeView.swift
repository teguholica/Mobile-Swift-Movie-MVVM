//
//  RatingBadgeView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct RatingBadgeView: View {
    private let rating: Double

    public init(rating: Double) {
        self.rating = rating
    }

    public var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(CinemaTokens.Colors.gold)
            Text(String(format: "%.1f", rating))
                .font(.caption.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
    }
}

#Preview {
    ZStack {
        Color.black
        RatingBadgeView(rating: 8.4)
    }
}
