//
//  ImagePipelineTests.swift
//  Mobile-Swift-Movie-MVVM
//

import Testing
import UIKit
@testable import Mobile_Swift_Movie_MVVM

struct ImagePipelineTests {

    private final class Counter: @unchecked Sendable {
        private let lock = NSLock()
        private var value = 0

        func increment() {
            lock.lock()
            value += 1
            lock.unlock()
        }

        var count: Int {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
    }

    private func makeImage() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func makeURL() -> URL {
        URL(string: "https://example.com/poster.jpg")!
    }

    @Test func testCachesSuccessfulLoads() async throws {
        let counter = Counter()
        let image = makeImage()
        let pipeline = ImagePipeline(cache: ImageMemoryCache()) { _ in
            counter.increment()
            return LoadedImage(image: image)
        }

        let first = try await pipeline.image(for: makeURL())
        let second = try await pipeline.image(for: makeURL())

        #expect(first.image === second.image)
        #expect(counter.count == 1)
    }

    @Test func testDeduplicatesConcurrentRequests() async throws {
        let counter = Counter()
        let image = makeImage()
        let pipeline = ImagePipeline(cache: ImageMemoryCache()) { _ in
            counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return LoadedImage(image: image)
        }

        async let first = pipeline.image(for: makeURL())
        async let second = pipeline.image(for: makeURL())

        let (firstImage, secondImage) = try await (first, second)

        #expect(firstImage.image === secondImage.image)
        #expect(counter.count == 1)
    }

    @Test func testRetriesOnceBeforeFailing() async {
        struct LoadFailure: Error {}

        let counter = Counter()
        let pipeline = ImagePipeline(cache: ImageMemoryCache()) { _ in
            counter.increment()
            throw LoadFailure()
        }

        await #expect(throws: LoadFailure.self) {
            _ = try await pipeline.image(for: makeURL())
        }

        #expect(counter.count == 2)
    }

    @Test func testFailureIsNotCached() async throws {
        struct LoadFailure: Error {}

        let counter = Counter()
        let image = makeImage()
        let pipeline = ImagePipeline(cache: ImageMemoryCache()) { _ in
            counter.increment()
            if counter.count <= 2 {
                throw LoadFailure()
            }
            return LoadedImage(image: image)
        }

        await #expect(throws: LoadFailure.self) {
            _ = try await pipeline.image(for: makeURL())
        }

        let loaded = try await pipeline.image(for: makeURL())

        #expect(loaded.image === image)
        #expect(counter.count == 3)
    }
}
