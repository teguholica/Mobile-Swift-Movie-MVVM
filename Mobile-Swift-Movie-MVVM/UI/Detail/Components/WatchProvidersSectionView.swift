//
//  WatchProvidersSectionView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct WatchProvidersSectionView: View {
    let providers: WatchProviders

    public init(providers: WatchProviders) {
        self.providers = providers
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Where to Watch")
                .font(.headline.weight(.bold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)

            if let link = providers.link {
                Link(destination: link) {
                    groupsContent
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens availability page")
            } else {
                groupsContent
            }

            Text("Streaming data provided by JustWatch")
                .font(.caption2)
                .foregroundStyle(CinemaTokens.Colors.textMuted)
        }
        .padding(.horizontal, 20)
    }

    private var groupsContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if providers.groups.isEmpty {
                Text("See all options")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CinemaTokens.Colors.accent)
            }

            ForEach(providers.groups.sorted { $0.kind.sortOrder < $1.kind.sortOrder }) { group in
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.kind.title)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CinemaTokens.Colors.textSecondary)

                    HStack(spacing: 8) {
                        ForEach(Array(group.providers.prefix(4))) { provider in
                            providerLogo(provider)
                        }

                        if group.providers.count > 4 {
                            Text("+\(group.providers.count - 4)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CinemaTokens.Colors.textSecondary)
                                .frame(width: 44, height: 44)
                                .background(CinemaTokens.Colors.elevated)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                                )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func providerLogo(_ provider: WatchProvider) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(CinemaTokens.Colors.elevated)

            if let path = provider.logoPath, let url = TMDBConfig.imageURL(path: path, size: "w92") {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(5)
                    default:
                        Color.clear
                    }
                }
            }
        }
        .frame(width: 44, height: 44)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(provider.name)
    }
}
