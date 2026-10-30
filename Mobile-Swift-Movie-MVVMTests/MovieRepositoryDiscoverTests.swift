//
//  MovieRepositoryDiscoverTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

private final class DiscoverRecordingNetworkService: TMDBNetworkServiceProtocol, @unchecked Sendable {
    var requestedEndpoints: [TMDBEndpoint] = []

    func request<T: Decodable>(_ endpoint: TMDBEndpoint) async throws -> T {
        requestedEndpoints.append(endpoint)
        let payload: String
        if endpoint.path == "/genre/movie/list" {
            payload = #"{"genres":[{"id":28,"name":"Action"},{"id":37,"name":"Western"}]}"#
        } else {
            payload = #"{"page":1,"results":[],"total_pages":1,"total_results":0}"#
        }
        return try JSONDecoder().decode(T.self, from: Data(payload.utf8))
    }
}

struct MovieRepositoryDiscoverTests {

    private func makeSUT() -> (MovieRepositoryImpl, DiscoverRecordingNetworkService) {
        let network = DiscoverRecordingNetworkService()
        let repository = MovieRepositoryImpl(
            networkService: network,
            localDataSource: SwiftDataFavoriteDataSource.createInMemory()
        )
        return (repository, network)
    }

    @Test func testDiscoverWithSingleGenreUsesPopularitySort() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(
            filters: DiscoverFilters(genreIds: [28]),
            page: 1
        )

        let endpoint = try #require(network.requestedEndpoints.first)
        let query = endpoint.queryItems

        #expect(endpoint.path == "/discover/movie")
        #expect(query.first(where: { $0.name == "page" })?.value == "1")
        #expect(query.first(where: { $0.name == "sort_by" })?.value == "popularity.desc")
        #expect(query.first(where: { $0.name == "with_genres" })?.value == "28")
        #expect(query.first(where: { $0.name == "vote_average.gte" }) == nil)
        #expect(query.first(where: { $0.name == "vote_count.gte" }) == nil)
        #expect(query.first(where: { $0.name == "primary_release_date.gte" }) == nil)
    }

    @Test func testDiscoverWithoutGenresOmitsGenreParameter() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(filters: DiscoverFilters(), page: 2)

        let endpoint = try #require(network.requestedEndpoints.first)
        let query = endpoint.queryItems

        #expect(query.first(where: { $0.name == "with_genres" }) == nil)
        #expect(query.first(where: { $0.name == "page" })?.value == "2")
    }

    @Test func testDiscoverEncodesMultipleGenresAsOrSeparator() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(
            filters: DiscoverFilters(genreIds: [28, 12]),
            page: 1
        )

        let endpoint = try #require(network.requestedEndpoints.first)
        #expect(endpoint.queryItems.first(where: { $0.name == "with_genres" })?.value == "28|12")
    }

    @Test func testDiscoverEncodesReleaseYearRange() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(
            filters: DiscoverFilters(yearRange: 2000...2010),
            page: 1
        )

        let endpoint = try #require(network.requestedEndpoints.first)
        let query = endpoint.queryItems

        #expect(query.first(where: { $0.name == "primary_release_date.gte" })?.value == "2000-01-01")
        #expect(query.first(where: { $0.name == "primary_release_date.lte" })?.value == "2010-12-31")
    }

    @Test func testDiscoverEncodesMinimumRatingAndVoteFloor() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(
            filters: DiscoverFilters(minRating: 7.5),
            page: 1
        )

        let endpoint = try #require(network.requestedEndpoints.first)
        let query = endpoint.queryItems

        #expect(query.first(where: { $0.name == "vote_average.gte" })?.value == "7.5")
        #expect(query.first(where: { $0.name == "vote_count.gte" })?.value == "50")
    }

    @Test func testRatingSortAddsVoteFloor() async throws {
        let (repository, network) = makeSUT()

        _ = try await repository.discoverMovies(
            filters: DiscoverFilters(sort: .rating),
            page: 1
        )

        let endpoint = try #require(network.requestedEndpoints.first)
        let query = endpoint.queryItems

        #expect(query.first(where: { $0.name == "sort_by" })?.value == "vote_average.desc")
        #expect(query.first(where: { $0.name == "vote_count.gte" })?.value == "50")
        #expect(query.first(where: { $0.name == "vote_average.gte" }) == nil)
    }

    @Test func testGetGenresMapsCatalogueIntoDomainGenres() async throws {
        let (repository, network) = makeSUT()

        let genres = try await repository.getGenres()

        #expect(genres == [Genre(id: 28, name: "Action"), Genre(id: 37, name: "Western")])
        #expect(network.requestedEndpoints.first?.path == "/genre/movie/list")
    }

    @Test func testDiscoverMapsEverySortOption() async throws {
        let expectations: [(DiscoverSort, String)] = [
            (.popularity, "popularity.desc"),
            (.rating, "vote_average.desc"),
            (.newest, "primary_release_date.desc"),
            (.title, "title.asc")
        ]

        for (sort, expected) in expectations {
            let (repository, network) = makeSUT()

            _ = try await repository.discoverMovies(
                filters: DiscoverFilters(genreIds: [28], sort: sort),
                page: 1
            )

            let endpoint = try #require(network.requestedEndpoints.first)
            #expect(endpoint.queryItems.first(where: { $0.name == "sort_by" })?.value == expected)
        }
    }
}
