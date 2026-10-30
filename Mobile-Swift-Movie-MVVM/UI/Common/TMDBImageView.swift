//
//  TMDBImageView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI
import UIKit

public struct TMDBImageView: View {
    private let path: String?
    private let size: String
    private let contentMode: ContentMode

    @State private var loadedImage: LoadedImage?
    @State private var loadedURL: URL?
    @State private var didFail = false

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
        content
            .task(id: url) {
                await load()
            }
    }

    @ViewBuilder
    private var content: some View {
        if let loadedImage {
            Image(uiImage: loadedImage.image)
                .resizable()
                .aspectRatio(contentMode: contentMode)
        } else if url == nil || didFail {
            placeholderView
        } else {
            loadingView
        }
    }

    private var url: URL? {
        TMDBConfig.imageURL(path: path, size: size)
    }

    private var loadingView: some View {
        ZStack {
            CinemaTokens.Colors.elevated
            ProgressView()
                .scaleEffect(0.8)
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

    @MainActor
    private func load() async {
        guard let url else {
            loadedImage = nil
            loadedURL = nil
            didFail = false
            return
        }

        if loadedURL != url {
            loadedImage = nil
            didFail = false
            loadedURL = url
        }

        if let cached = ImagePipeline.shared.cachedImage(for: url) {
            loadedImage = cached
            didFail = false
            return
        }

        do {
            let image = try await ImagePipeline.shared.image(for: url)
            guard !Task.isCancelled, self.url == url else { return }
            loadedImage = image
            didFail = false
        } catch is CancellationError {
        } catch {
            guard !Task.isCancelled, self.url == url else { return }
            didFail = true
        }
    }
}

#Preview {
    TMDBImageView(path: "/sample.jpg")
        .frame(width: 150, height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 12))
}
