//
//  SwiftDataFavoriteDataSource.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import SwiftData

public protocol SwiftDataFavoriteDataSourceProtocol: Sendable {
    func getFavorites() async throws -> [Movie]
    func toggleFavorite(movie: Movie) async throws -> Bool
    func isFavorite(movieId: Int) async throws -> Bool
    func removeFavorite(movieId: Int) async throws
}

public actor SwiftDataFavoriteDataSource: SwiftDataFavoriteDataSourceProtocol {
    private let modelContainer: ModelContainer

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    public static func createDefault() -> SwiftDataFavoriteDataSource {
        let schema = Schema([FavoriteMovieItem.self])
        do {
            let container = try ModelContainer(for: schema)
            return SwiftDataFavoriteDataSource(modelContainer: container)
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error)")
        }
    }

    public static func createInMemory() -> SwiftDataFavoriteDataSource {
        let schema = Schema([FavoriteMovieItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return SwiftDataFavoriteDataSource(modelContainer: container)
        } catch {
            fatalError("Failed to initialize in-memory SwiftData ModelContainer: \(error)")
        }
    }

    public func getFavorites() async throws -> [Movie] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieItem>(
            sortBy: [SortDescriptor(\.addedAt, order: .reverse)]
        )
        let items = try context.fetch(descriptor)
        return items.map { $0.toDomain() }
    }

    public func isFavorite(movieId: Int) async throws -> Bool {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieItem>(
            predicate: #Predicate { $0.id == movieId }
        )
        let count = try context.fetchCount(descriptor)
        return count > 0
    }

    public func toggleFavorite(movie: Movie) async throws -> Bool {
        let context = ModelContext(modelContainer)
        let movieId = movie.id
        let descriptor = FetchDescriptor<FavoriteMovieItem>(
            predicate: #Predicate { $0.id == movieId }
        )
        let existing = try context.fetch(descriptor)

        if let itemToDelete = existing.first {
            context.delete(itemToDelete)
            try context.save()
            return false
        } else {
            let newItem = FavoriteMovieItem(
                id: movie.id,
                title: movie.title,
                overview: movie.overview,
                posterPath: movie.posterPath,
                backdropPath: movie.backdropPath,
                releaseDate: movie.releaseDate,
                voteAverage: movie.voteAverage,
                voteCount: movie.voteCount
            )
            context.insert(newItem)
            try context.save()
            return true
        }
    }

    public func removeFavorite(movieId: Int) async throws {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FavoriteMovieItem>(
            predicate: #Predicate { $0.id == movieId }
        )
        let existing = try context.fetch(descriptor)
        for item in existing {
            context.delete(item)
        }
        try context.save()
    }
}
