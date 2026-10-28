//
//  SettingsView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct SettingsView: View {
    @Environment(ThemeManager.self) private var themeManager
    private let appInfo: AppInfo

    public init(appInfo: AppInfo = .current()) {
        self.appInfo = appInfo
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Appearance Section
                    appearanceSection

                    // About & Identity Section
                    aboutSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
            }
            .background(CinemaTokens.Colors.canvas.ignoresSafeArea())
            .navigationTitle("Settings")
        }
    }

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("INTERFACE")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.gold)

                Text("Appearance")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }

            HStack(spacing: 12) {
                ForEach(AppearanceMode.allCases) { mode in
                    themeCard(for: mode)
                }
            }
        }
    }

    private func themeCard(for mode: AppearanceMode) -> some View {
        let isSelected = themeManager.currentMode == mode

        return Button {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                themeManager.currentMode = mode
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    themeMockup(for: mode)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(CinemaTokens.Colors.gold)
                            .background(Circle().fill(.black.opacity(0.6)))
                            .padding(5)
                    }
                }

                Text(mode.title)
                    .font(.caption.weight(isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? CinemaTokens.Colors.textPrimary : CinemaTokens.Colors.textSecondary)
            }
            .padding(8)
            .background(CinemaTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                    .stroke(
                        isSelected ? CinemaTokens.Colors.gold : CinemaTokens.Colors.glassStroke,
                        lineWidth: isSelected ? 2 : 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title) theme\(isSelected ? ", selected" : "")")
    }

    private func themeMockup(for mode: AppearanceMode) -> some View {
        Group {
            switch mode {
            case .system:
                ZStack {
                    LinearGradient(
                        stops: [
                            .init(color: Color(white: 0.92), location: 0.0),
                            .init(color: Color(white: 0.92), location: 0.5),
                            .init(color: Color(red: 20/255, green: 22/255, blue: 31/255), location: 0.5),
                            .init(color: Color(red: 20/255, green: 22/255, blue: 31/255), location: 1.0)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    Image(systemName: "circle.righthalf.filled")
                        .font(.system(size: 20))
                        .foregroundStyle(.gray)
                }
            case .light:
                ZStack {
                    Color(red: 244/255, green: 246/255, blue: 250/255)

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.gray.opacity(0.35))
                            .frame(width: 32, height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 44, height: 16)
                    }
                }
            case .dark:
                ZStack {
                    Color(red: 16/255, green: 18/255, blue: 24/255)

                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(CinemaTokens.Colors.gold.opacity(0.8))
                            .frame(width: 32, height: 5)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.18))
                            .frame(width: 44, height: 16)
                    }
                }
            }
        }
    }

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("APPLICATION")
                    .font(.caption2.weight(.heavy))
                    .tracking(1.5)
                    .foregroundStyle(CinemaTokens.Colors.crimson)

                Text("About")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CinemaTokens.Colors.textPrimary)
            }

            VStack(spacing: 14) {
                // Identity row
                HStack(spacing: 16) {
                    ZStack {
                        LinearGradient(
                            colors: [CinemaTokens.Colors.crimson, CinemaTokens.Colors.crimson.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        Image(systemName: "film.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 52, height: 52)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
                    )

                    VStack(alignment: .leading, spacing: 3) {
                        Text(appInfo.appName)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(CinemaTokens.Colors.textPrimary)

                        Text("Version \(appInfo.formattedVersion)")
                            .font(.subheadline)
                            .foregroundStyle(CinemaTokens.Colors.textSecondary)
                    }

                    Spacer()
                }

                Divider()
                    .overlay(CinemaTokens.Colors.glassStroke)

                // TMDB Partner Link
                Link(destination: URL(string: "https://www.themoviedb.org")!) {
                    HStack(spacing: 10) {
                        Image(systemName: "popcorn")
                            .font(.system(size: 16))
                            .foregroundStyle(CinemaTokens.Colors.gold)

                        Text("Powered by The Movie Database")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(CinemaTokens.Colors.textPrimary)

                        Spacer()

                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(CinemaTokens.Colors.textMuted)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(CinemaTokens.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: CinemaTokens.Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: CinemaTokens.Radius.card)
                    .stroke(CinemaTokens.Colors.glassStroke, lineWidth: 0.5)
            )

            // Disclaimer text
            Text("This product uses the TMDB API but is not endorsed or certified by TMDB.")
                .font(.caption2)
                .foregroundStyle(CinemaTokens.Colors.textMuted)
                .padding(.horizontal, 4)
        }
    }
}

#Preview {
    SettingsView()
        .environment(ThemeManager())
}
