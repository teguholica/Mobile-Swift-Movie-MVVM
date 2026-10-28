//
//  SwiftDataFavoriteDataSourceTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct SwiftDataFavoriteDataSourceTests {

    private func makeMovie(id: Int, title: String) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: "Overview for \(title)",
            posterPath: "/poster\(id).jpg",
            backdropPath: "/backdrop\(id).jpg",
            releaseDate: "2024-05-01",
            voteAverage: 8.1,
            voteCount: 450
        )
    }

    @Test func testSwiftDataFavoriteCRUDOperations() async throws {
        let dataSource = SwiftDataFavoriteDataSource.createInMemory()
        let movie1 = makeMovie(id: 100, title: "Oppenheimer")
        let movie2 = makeMovie(id: 200, title: "Barbie")

        // 1. Initial should be empty
        let initialList = try await dataSource.getFavorites()
        #expect(initialList.isEmpty)

        // 2. Check isFavorite
        let isFav1 = try await dataSource.isFavorite(movieId: 100)
        #expect(isFav1 == false)

        // 3. Toggle ON movie1
        let toggledOn1 = try await dataSource.toggleFavorite(movie: movie1)
        #expect(toggledOn1 == true)
        #expect(try await dataSource.isFavorite(movieId: 100) == true)

        // 4. Toggle ON movie2
        let toggledOn2 = try await dataSource.toggleFavorite(movie: movie2)
        #expect(toggledOn2 == true)

        let listAfterTwo = try await dataSource.getFavorites()
        #expect(listAfterTwo.count == 2)

        // 5. Toggle OFF movie1
        let toggledOff1 = try await dataSource.toggleFavorite(movie: movie1)
        #expect(toggledOff1 == false)
        #expect(try await dataSource.isFavorite(movieId: 100) == false)

        let listAfterToggleOff = try await dataSource.getFavorites()
        #expect(listAfterToggleOff.count == 1)
        #expect(listAfterToggleOff.first?.id == 200)

        // 6. Explicit removeFavorite
        try await dataSource.removeFavorite(movieId: 200)
        #expect(try await dataSource.isFavorite(movieId: 200) == false)
        #expect(try await dataSource.getFavorites().isEmpty)
    }
}
