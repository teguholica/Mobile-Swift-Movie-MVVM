//
//  DiscoverFilterBar.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

struct DiscoverFilterBar: View {
    let activeFilterCount: Int
    let categorySummary: String
    let categoryAccessibilityLabel: String
    let onFilter: () -> Void
    let onCategory: () -> Void

    var body: some View {
        HStack {
            Button(action: onFilter) {
                HStack(spacing: 5) {
                    Image(systemName: "line.3.horizontal.decrease")
                        .font(.system(size: 13, weight: .semibold))

                    Text("Filter")
                        .font(.caption.weight(.semibold))

                    if activeFilterCount > 0 {
                        Text("· \(activeFilterCount)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(CinemaTokens.Colors.gold)
                    }

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(CinemaTokens.Colors.elevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Filter")
            .accessibilityValue(activeFilterCount == 0 ? "No filters" : "\(activeFilterCount) filters")

            Button(action: onCategory) {
                HStack(spacing: 5) {
                    Text(categorySummary)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .foregroundStyle(CinemaTokens.Colors.textPrimary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(CinemaTokens.Colors.elevated)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(categoryAccessibilityLabel)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
