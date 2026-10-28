//
//  TMDBImageView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct TMDBImageView: View {
    private let path: String?
    private let size: String
    private let contentMode: ContentMode

    public init(
        path: String?,
        size: String = "w500",
        contentMode: ContentMode = .fill
    ) {
        self.path = path
        self.size = size
        self.contentMode = contentMode
    }

    public var body: some View {
        if let url = TMDBConfig.imageURL(path: path, size: size) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        CinemaTokens.Colors.elevated
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholderView
                @unknown default:
                    placeholderView
                }
            }
        } else {
            placeholderView
        }
    }

    private var placeholderView: some View {
        ZStack {
            CinemaTokens.Colors.elevated
            VStack(spacing: 6) {
                Image(systemName: "film")
                    .font(.system(size: 24))
                    .foregroundStyle(CinemaTokens.Colors.textSecondary)
                Text("No Image")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(CinemaTokens.Colors.textMuted)
            }
        }
    }
}

#Preview {
    TMDBImageView(path: "/sample.jpg")
        .frame(width: 150, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
