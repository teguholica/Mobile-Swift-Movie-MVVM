//
//  AppDestinations.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct AppDestinations: ViewModifier {
    @Environment(AppContainer.self) private var container
    private let onFavoriteChanged: (() -> Void)?

    public init(onFavoriteChanged: (() -> Void)? = nil) {
        self.onFavoriteChanged = onFavoriteChanged
    }

    public func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .movie(let id):
                MovieDetailView(
                    viewModel: container.makeMovieDetailViewModel(movieId: id),
                    onToggleFavorite: onFavoriteChanged
                )
            case .person(let id, let name, let profilePath):
                PersonView(
                    name: name,
                    profilePath: profilePath,
                    viewModel: container.makePersonViewModel(personId: id)
                )
            }
        }
    }
}

public extension View {
    func appDestinations(onFavoriteChanged: (() -> Void)? = nil) -> some View {
        modifier(AppDestinations(onFavoriteChanged: onFavoriteChanged))
    }
}
