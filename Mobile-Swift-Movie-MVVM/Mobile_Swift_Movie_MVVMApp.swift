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
    private let container: AppContainer

    init() {
        let schema = Schema([FavoriteMovieItem.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let modelContainer = try ModelContainer(for: schema, configurations: [configuration])
            let dataSource = SwiftDataFavoriteDataSource(modelContainer: modelContainer)
            container = AppContainer(
                movieRepository: MovieRepositoryImpl(localDataSource: dataSource)
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView(container: container)
                .environment(container)
                .environment(themeManager)
                .preferredColorScheme(themeManager.colorScheme)
        }
    }
}
