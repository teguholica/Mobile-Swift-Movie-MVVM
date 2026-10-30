//
//  PersonViewModel.swift
//  Mobile-Swift-Movie-MVVM
//

import Foundation
import Observation

@Observable
public final class PersonViewModel {
    public enum State: Equatable {
        case loading
        case loaded(PersonProfile)
        case error(String)
    }

    public enum Tab: String, CaseIterable, Identifiable, Equatable {
        case info
        case film

        public var id: String { rawValue }

        public var title: String {
            switch self {
            case .info:
                return "Info"
            case .film:
                return "Film"
            }
        }
    }

    public let personId: Int
    public var state: State = .loading
    public var profile: PersonProfile?
    public var selectedTab: Tab = .info

    private let getPersonProfileUseCase: GetPersonProfileUseCaseProtocol

    public init(
        personId: Int,
        getPersonProfileUseCase: GetPersonProfileUseCaseProtocol
    ) {
        self.personId = personId
        self.getPersonProfileUseCase = getPersonProfileUseCase
    }

    @MainActor
    public func fetchProfile() async {
        guard profile == nil else { return }
        state = .loading

        do {
            let profile = try await getPersonProfileUseCase.execute(id: personId)
            self.profile = profile
            self.state = .loaded(profile)
        } catch {
            self.state = .error(error.localizedDescription)
        }
    }
}
