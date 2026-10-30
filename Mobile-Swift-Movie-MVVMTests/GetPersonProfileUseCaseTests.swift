//
//  GetPersonProfileUseCaseTests.swift
//  Mobile-Swift-Movie-MVVMTests
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct GetPersonProfileUseCaseTests {

    private func makeProfile(id: Int = 31, name: String = "Tom Hanks") -> PersonProfile {
        PersonProfile(
            id: id,
            name: name,
            profilePath: "/tom.jpg",
            knownForDepartment: "Acting",
            credits: [
                PersonMovieCredit(
                    id: 13,
                    title: "Forrest Gump",
                    posterPath: "/gump.jpg",
                    releaseDate: "1994-06-23",
                    voteAverage: 8.5,
                    voteCount: 24000,
                    character: "Forrest Gump"
                )
            ]
        )
    }

    @Test func testExecuteReturnsRepositoryProfile() async throws {
        let repository = MockMovieRepository()
        let profile = makeProfile()
        repository.personProfileResult = .success(profile)

        let useCase = GetPersonProfileUseCase(repository: repository)
        let result = try await useCase.execute(id: 31)

        #expect(result == profile)
        #expect(repository.requestedPersonProfileId == 31)
    }

    @Test func testExecutePropagatesRepositoryError() async {
        struct FetchError: Error, LocalizedError {
            var errorDescription: String? { "Person not found" }
        }

        let repository = MockMovieRepository()
        repository.personProfileResult = .failure(FetchError())

        let useCase = GetPersonProfileUseCase(repository: repository)

        await #expect(throws: FetchError.self) {
            _ = try await useCase.execute(id: 999)
        }
    }
}
