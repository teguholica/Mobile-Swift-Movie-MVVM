//
//  LoadingView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct LoadingView: View {
    private let message: String

    public init(message: String = "Loading movies...") {
        self.message = message
    }

    public var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(1.2)
            Text(message)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(CinemaTokens.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    LoadingView()
}
