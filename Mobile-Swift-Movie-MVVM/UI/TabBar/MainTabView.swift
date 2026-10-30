//
//  MainTabView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Tab = .home
    @State private var homeViewModel: HomeViewModel
    @State private var searchViewModel: SearchViewModel
    @State private var discoverViewModel: DiscoverViewModel
    @State private var favoritesViewModel: FavoritesViewModel

    public enum Tab: Hashable {
        case home
        case search
        case discover
        case favorites
        case settings
    }

    public init(container: AppContainer) {
        _homeViewModel = State(initialValue: container.makeHomeViewModel())
        _searchViewModel = State(initialValue: container.makeSearchViewModel())
        _discoverViewModel = State(initialValue: container.makeDiscoverViewModel())
        _favoritesViewModel = State(initialValue: container.makeFavoritesViewModel())
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(viewModel: homeViewModel)
                .tabItem {
                    Label("Home", systemImage: "film.stack")
                }
                .tag(Tab.home)

            SearchView(viewModel: searchViewModel)
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            DiscoverView(viewModel: discoverViewModel)
                .tabItem {
                    Label("Discover", systemImage: "sparkles.tv")
                }
                .tag(Tab.discover)

            FavoritesView(viewModel: favoritesViewModel)
                .tabItem {
                    Label("Favorites", systemImage: "bookmark.fill")
                }
                .tag(Tab.favorites)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
    }
}

#if DEBUG
#Preview {
    MainTabView(container: AppContainer.preview)
        .environment(AppContainer.preview)
        .environment(ThemeManager())
}
#endif
