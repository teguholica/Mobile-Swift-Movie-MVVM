//
//  Mobile_Swift_Movie_MVVMApp.swift
//  Mobile-Swift-Movie-MVVM
//
//  Created by Macbook Cakra M4 on 28/10/26.
//

import SwiftUI
import SwiftData

@main
struct Mobile_Swift_Movie_MVVMApp: App {
    @State private var themeManager = ThemeManager()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            FavoriteMovieItem.self,
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
        .modelContainer(sharedModelContainer)
    }
}
