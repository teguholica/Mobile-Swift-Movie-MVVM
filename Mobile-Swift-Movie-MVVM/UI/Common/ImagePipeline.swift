//
//  ImagePipeline.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import UIKit

struct LoadedImage: @unchecked Sendable {
    let image: UIImage
}

final class ImageMemoryCache: @unchecked Sendable {
    static let shared = ImageMemoryCache()

    private final class Box {
        let image: LoadedImage

        init(_ image: LoadedImage) {
            self.image = image
        }
    }

    private let cache = NSCache<NSURL, Box>()

    init(countLimit: Int = 200) {
        cache.countLimit = countLimit
    }

    func image(for url: URL) -> LoadedImage? {
        cache.object(forKey: url as NSURL)?.image
    }

    func insert(_ image: LoadedImage, for url: URL) {
        cache.setObject(Box(image), forKey: url as NSURL)
    }
}

actor ImagePipeline {
    typealias Loader = @Sendable (URL) async throws -> LoadedImage

    static let shared = ImagePipeline()

    private let cache: ImageMemoryCache
    private let loader: Loader
    private var tasks: [URL: Task<LoadedImage, Error>] = [:]

    init(cache: ImageMemoryCache = .shared, loader: Loader? = nil) {
        self.cache = cache
        self.loader = loader ?? { url in
            try await ImagePipeline.fetch(url)
        }
    }

    nonisolated func cachedImage(for url: URL) -> LoadedImage? {
        cache.image(for: url)
    }

    func image(for url: URL) async throws -> LoadedImage {
        if let cached = cache.image(for: url) {
            return cached
        }

        if let existing = tasks[url] {
            return try await existing.value
        }

        let loader = self.loader
        let task = Task.detached(priority: .userInitiated) {
            try await Self.loadWithRetry(url, loader: loader)
        }
        tasks[url] = task

        defer { tasks[url] = nil }

        let image = try await task.value
        cache.insert(image, for: url)
        return image
    }

    private static func loadWithRetry(_ url: URL, loader: Loader) async throws -> LoadedImage {
        var lastError: Error?

        for attempt in 0..<2 {
            do {
                return try await loader(url)
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                lastError = error
                if attempt == 0 {
                    try? await Task.sleep(for: .milliseconds(300))
                }
            }
        }

        throw lastError ?? URLError(.unknown)
    }

    private static func fetch(_ url: URL) async throws -> LoadedImage {
        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            throw URLError(.badServerResponse)
        }

        guard let image = UIImage(data: data) else {
            throw URLError(.cannotDecodeContentData)
        }

        return LoadedImage(image: image)
    }
}
