//
//  MovieRepositoryImpl.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation

public final class MovieRepositoryImpl: MovieRepositoryProtocol {
    private final class MovieDetailCacheEntry {
        let detail: MovieDetail

        init(_ detail: MovieDetail) {
            self.detail = detail
        }
    }

    private final class PersonProfileCacheEntry {
        let profile: PersonProfile

        init(_ profile: PersonProfile) {
            self.profile = profile
        }
    }

    private let networkService: TMDBNetworkServiceProtocol
    private let localDataSource: SwiftDataFavoriteDataSourceProtocol
    private let regionCodeProvider: @Sendable () -> String
    private let detailCache = NSCache<NSString, MovieDetailCacheEntry>()
    private let personCache = NSCache<NSString, PersonProfileCacheEntry>()

    public init(
        networkService: TMDBNetworkServiceProtocol = TMDBNetworkService(),
        localDataSource: SwiftDataFavoriteDataSourceProtocol,
        regionCodeProvider: @escaping @Sendable () -> String = {
            Locale.current.region?.identifier ?? "US"
        }
    ) {
        self.networkService = networkService
        self.localDataSource = localDataSource
        self.regionCodeProvider = regionCodeProvider
    }

    public func getNowPlayingMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.nowPlaying(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getPopularMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.popular(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getTopRatedMovies(page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.topRated(page: page))
        return response.results.map { $0.toDomain() }
    }

    public func searchMovies(query: String, year: Int? = nil, page: Int = 1) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.search(query: query, year: year, page: page))
        return response.results.map { $0.toDomain() }
    }

    public func discoverMovies(filters: DiscoverFilters, page: Int) async throws -> [Movie] {
        let response: MovieResponseDTO = try await networkService.request(.discover(filters: filters, page: page))
        return response.results.map { $0.toDomain() }
    }

    public func getGenres() async throws -> [Genre] {
        let response: GenreListDTO = try await networkService.request(.genres)
        return response.genres.map { $0.toDomain() }
    }

    public func getMovieDetails(id: Int) async throws -> MovieDetail {
        let region = regionCodeProvider()
        let cacheKey = "\(id)-\(region)" as NSString

        if let cached = detailCache.object(forKey: cacheKey) {
            return cached.detail
        }

        let response: MovieDetailDTO = try await networkService.request(.detail(id: id))
        let videos = (response.videos?.results ?? []).map { $0.toDomain() }
        let cast = (response.credits?.cast ?? [])
            .sorted { $0.order < $1.order }
            .filter { $0.id > 0 && !$0.name.isEmpty }
            .prefix(10)
            .map { $0.toDomain() }
        let providers = mapProviders(response.watchProviders, region: region)
        let recommendedCandidates = (response.recommendations?.results ?? []).filter { $0.id != id }
        let similarCandidates = (response.similar?.results ?? []).filter { $0.id != id }
        let relatedDTOs = recommendedCandidates.isEmpty ? similarCandidates : recommendedCandidates
        let recommendedMovies = relatedDTOs.map { $0.toDomain() }
        let detail = response.toDomain(
            trailer: MovieVideo.best(from: videos),
            cast: cast,
            providers: providers,
            recommendedMovies: recommendedMovies
        )

        detailCache.setObject(MovieDetailCacheEntry(detail), forKey: cacheKey)
        return detail
    }

    public func getPersonProfile(id: Int) async throws -> PersonProfile {
        let cacheKey = "\(id)" as NSString

        if let cached = personCache.object(forKey: cacheKey) {
            return cached.profile
        }

        let response: PersonDTO = try await networkService.request(.person(id: id))
        let credits = Self.shapeCredits(response.movieCredits?.cast ?? [])
        let profile = response.toDomain(credits: credits)

        personCache.setObject(PersonProfileCacheEntry(profile), forKey: cacheKey)
        return profile
    }

    private static func shapeCredits(_ credits: [PersonCreditDTO]) -> [PersonMovieCredit] {
        let now = Date()
        var seenMovieIds = Set<Int>()
        var shaped: [(credit: PersonMovieCredit, releaseDate: Date)] = []

        for dto in credits {
            guard dto.id > 0, !dto.title.isEmpty else { continue }
            guard let releaseDateValue = dto.releaseDate,
                  !releaseDateValue.isEmpty,
                  let releaseDate = PersonDateFormatting.parse(releaseDateValue),
                  releaseDate <= now else {
                continue
            }
            guard seenMovieIds.insert(dto.id).inserted else { continue }
            shaped.append((dto.toDomain(), releaseDate))
        }

        return shaped
            .sorted { lhs, rhs in
                if lhs.releaseDate != rhs.releaseDate {
                    return lhs.releaseDate > rhs.releaseDate
                }
                return lhs.credit.title < rhs.credit.title
            }
            .map(\.credit)
    }

    private func mapProviders(_ dto: WatchProvidersResponseDTO?, region: String) -> WatchProviders? {
        guard let entry = dto?.results[region] else { return nil }

        let groups: [ProviderGroup] = [
            providerGroup(kind: .stream, providers: entry.flatrate),
            providerGroup(kind: .free, providers: entry.free),
            providerGroup(kind: .ads, providers: entry.ads),
            providerGroup(kind: .rent, providers: entry.rent),
            providerGroup(kind: .buy, providers: entry.buy)
        ].compactMap { $0 }

        guard !groups.isEmpty || entry.link != nil else { return nil }
        return WatchProviders(link: entry.link.flatMap(URL.init(string:)), groups: groups)
    }

    private func providerGroup(
        kind: ProviderGroupKind,
        providers: [WatchProviderDTO]?
    ) -> ProviderGroup? {
        let mapped = (providers ?? [])
            .sorted { $0.displayPriority < $1.displayPriority }
            .filter { $0.providerId > 0 && !$0.providerName.isEmpty }
            .map { $0.toDomain() }

        return mapped.isEmpty ? nil : ProviderGroup(kind: kind, providers: mapped)
    }

    public func getFavoriteMovies() async throws -> [Movie] {
        try await localDataSource.getFavorites()
    }

    public func toggleFavorite(movie: Movie) async throws -> Bool {
        try await localDataSource.toggleFavorite(movie: movie)
    }

    public func isFavorite(movieId: Int) async throws -> Bool {
        try await localDataSource.isFavorite(movieId: movieId)
    }

    public func removeFavorite(movieId: Int) async throws {
        try await localDataSource.removeFavorite(movieId: movieId)
    }
}
