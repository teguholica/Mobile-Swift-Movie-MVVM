//
//  MainTabView.swift
//  Mobile-Swift-Movie-MVVM
//

import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Tab = .home

    public enum Tab: Hashable {
        case home
        case search
        case favorites
        case settings
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "film.stack")
                }
                .tag(Tab.home)

            SearchView()
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(Tab.search)

            FavoritesView()
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

#Preview {
    MainTabView()
        .environment(ThemeManager())
}
