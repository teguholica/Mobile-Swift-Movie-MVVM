//
//  AppDestinations.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct AppDestinations: ViewModifier {
    private let onFavoriteChanged: (() -> Void)?

    public init(onFavoriteChanged: (() -> Void)? = nil) {
        self.onFavoriteChanged = onFavoriteChanged
    }

    public func body(content: Content) -> some View {
        content.navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .movie(let id):
                MovieDetailView(movieId: id, onToggleFavorite: onFavoriteChanged)
            case .person(let id, let name, let profilePath):
                PersonView(personId: id, name: name, profilePath: profilePath)
            }
        }
    }
}

public extension View {
    func appDestinations(onFavoriteChanged: (() -> Void)? = nil) -> some View {
        modifier(AppDestinations(onFavoriteChanged: onFavoriteChanged))
    }
}
