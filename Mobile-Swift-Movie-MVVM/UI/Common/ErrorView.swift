//
//  ErrorView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct ErrorView: View {
    private let title: String
    private let message: String
    private let retryAction: (() -> Void)?

    public init(
        title: String = "Unable to Load",
        message: String,
        retryAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
    }

    public var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack.fill")
                .font(.system(size: 44))
                .foregroundStyle(CinemaTokens.Colors.gold)

            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(CinemaTokens.Colors.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(CinemaTokens.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if let retryAction = retryAction {
                Button(action: retryAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(CinemaTokens.Colors.crimson)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    ErrorView(message: "Failed to load movie data. Please check your connection.") {
        print("Retry clicked")
    }
}
