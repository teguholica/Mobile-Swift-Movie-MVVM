//
//  PreviewMovieRepository.swift
//  Mobile-Swift-Movie-MVVM
//

#if DEBUG
import Foundation

final class PreviewMovieRepository: MovieRepositoryProtocol, @unchecked Sendable {
    private let movies: [Movie] = [
        Movie(
            id: 1,
            title: "Preview Movie One",
            overview: "A placeholder synopsis used by SwiftUI previews.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2025-01-01",
            voteAverage: 8.1,
            voteCount: 1234
        ),
        Movie(
            id: 2,
            title: "Preview Movie Two",
            overview: "Another placeholder synopsis for layout previews.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2024-06-14",
            voteAverage: 7.4,
            voteCount: 987
        ),
        Movie(
            id: 3,
            title: "Preview Movie Three",
            overview: "A third placeholder synopsis for list previews.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2023-11-03",
            voteAverage: 6.9,
            voteCount: 456
        )
    ]

    func getNowPlayingMovies(page: Int) async throws -> [Movie] {
        movies
    }

    func getPopularMovies(page: Int) async throws -> [Movie] {
        movies
    }

    func getTopRatedMovies(page: Int) async throws -> [Movie] {
        movies
    }

    func searchMovies(query: String, page: Int) async throws -> [Movie] {
        movies
    }

    func discoverMovies(genreId: Int, page: Int) async throws -> [Movie] {
        movies
    }

    func getMovieDetails(id: Int) async throws -> MovieDetail {
        MovieDetail(
            id: id,
            title: "Preview Movie",
            overview: "A placeholder synopsis used by SwiftUI previews.",
            posterPath: nil,
            backdropPath: nil,
            releaseDate: "2025-01-01",
            voteAverage: 8.1,
            voteCount: 1234,
            runtime: 128,
            tagline: "Preview tagline",
            status: "Released",
            genres: [Genre(id: 28, name: "Action"), Genre(id: 878, name: "Sci-Fi")],
            cast: [
                CastMember(id: 10, name: "Preview Actor", character: "Lead", profilePath: nil),
                CastMember(id: 11, name: "Preview Actress", character: "Support", profilePath: nil)
            ],
            recommendedMovies: movies
        )
    }

    func getPersonProfile(id: Int) async throws -> PersonProfile {
        PersonProfile(
            id: id,
            name: "Preview Person",
            profilePath: nil,
            knownForDepartment: "Acting",
            birthday: "1980-01-01",
            placeOfBirth: "Jakarta, Indonesia",
            biography: "A placeholder biography used by SwiftUI previews.",
            credits: movies.map { movie in
                PersonMovieCredit(
                    id: movie.id,
                    title: movie.title,
                    posterPath: movie.posterPath,
                    releaseDate: movie.releaseDate,
                    voteAverage: movie.voteAverage,
                    voteCount: movie.voteCount,
                    character: "Lead"
                )
            }
        )
    }

    func getFavoriteMovies() async throws -> [Movie] {
        Array(movies.prefix(2))
    }

    func toggleFavorite(movie: Movie) async throws -> Bool {
        true
    }

    func isFavorite(movieId: Int) async throws -> Bool {
        false
    }

    func removeFavorite(movieId: Int) async throws {}
}
#endif
