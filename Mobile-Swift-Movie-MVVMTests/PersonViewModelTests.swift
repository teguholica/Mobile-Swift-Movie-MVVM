//
//  PersonViewModelTests.swift
//  Mobile-Swift-Movie-MVVM
//

import Testing
import Foundation
@testable import Mobile_Swift_Movie_MVVM

struct PersonViewModelTests {

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

    private func makeSUT(
        personId: Int = 31,
        repository: MockMovieRepository = MockMovieRepository()
    ) -> (PersonViewModel, MockMovieRepository) {
        let useCase = GetPersonProfileUseCase(repository: repository)
        let viewModel = PersonViewModel(
            personId: personId,
            getPersonProfileUseCase: useCase
        )
        return (viewModel, repository)
    }

    @Test func testInitialStateIsLoading() {
        let (viewModel, _) = makeSUT(personId: 31)

        #expect(viewModel.state == .loading)
        #expect(viewModel.profile == nil)
        #expect(viewModel.personId == 31)
    }

    @Test func testFetchProfileSuccessUpdatesStateToLoaded() async {
        let (viewModel, repository) = makeSUT(personId: 31)
        let profile = makeProfile()
        repository.personProfileResult = .success(profile)

        await viewModel.fetchProfile()

        #expect(viewModel.state == .loaded(profile))
        #expect(viewModel.profile?.name == "Tom Hanks")
        #expect(repository.requestedPersonProfileId == 31)
        #expect(repository.getPersonProfileCallCount == 1)
    }

    @Test func testFetchProfileFailureUpdatesStateToError() async {
        struct FetchError: Error, LocalizedError {
            var errorDescription: String? { "Person not found" }
        }

        let (viewModel, repository) = makeSUT(personId: 999)
        repository.personProfileResult = .failure(FetchError())

        await viewModel.fetchProfile()

        #expect(viewModel.state == .error("Person not found"))
        #expect(viewModel.profile == nil)
    }

    @Test func testRetryAfterErrorLoadsProfile() async {
        let (viewModel, repository) = makeSUT(personId: 31)
        repository.personProfileResult = .failure(URLError(.notConnectedToInternet))

        await viewModel.fetchProfile()
        guard case .error = viewModel.state else {
            Issue.record("Expected error state before retry")
            return
        }

        let profile = makeProfile()
        repository.personProfileResult = .success(profile)

        await viewModel.fetchProfile()

        #expect(viewModel.state == .loaded(profile))
        #expect(repository.getPersonProfileCallCount == 2)
    }

    @Test func testInitialTabIsInfo() {
        let (viewModel, _) = makeSUT()

        #expect(viewModel.selectedTab == .info)
        #expect(PersonViewModel.Tab.info.title == "Info")
        #expect(PersonViewModel.Tab.film.title == "Film")
    }

    @Test func testSwitchingTabKeepsLoadedProfile() async {
        let (viewModel, repository) = makeSUT(personId: 31)
        let profile = makeProfile()
        repository.personProfileResult = .success(profile)

        await viewModel.fetchProfile()
        viewModel.selectedTab = .film

        #expect(viewModel.selectedTab == .film)
        #expect(viewModel.state == .loaded(profile))
        #expect(repository.getPersonProfileCallCount == 1)
    }

    @Test func testRetryPreservesSelectedTab() async {
        let (viewModel, repository) = makeSUT(personId: 31)
        viewModel.selectedTab = .film
        repository.personProfileResult = .failure(URLError(.timedOut))

        await viewModel.fetchProfile()
        guard case .error = viewModel.state else {
            Issue.record("Expected error state before retry")
            return
        }
        #expect(viewModel.selectedTab == .film)

        let profile = makeProfile()
        repository.personProfileResult = .success(profile)

        await viewModel.fetchProfile()

        #expect(viewModel.selectedTab == .film)
        #expect(viewModel.state == .loaded(profile))
        #expect(repository.getPersonProfileCallCount == 2)
    }

    @Test func testFetchProfileDoesNotRefetchAfterLoad() async {
        let (viewModel, repository) = makeSUT(personId: 31)
        repository.personProfileResult = .success(makeProfile())

        await viewModel.fetchProfile()
        await viewModel.fetchProfile()

        #expect(repository.getPersonProfileCallCount == 1)
    }
}
