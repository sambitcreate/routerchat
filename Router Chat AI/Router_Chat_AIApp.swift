//
//  Router_Chat_AIApp.swift
//  Router Chat AI
//
//  Created by Sambit Biswas on 4/14/25.
//

import SwiftUI
import SwiftData

@main
struct Router_Chat_AIApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
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
            if !hasCompletedOnboarding {
                OnboardingView()
                    .colorTheme(isDarkMode ? .dark : .light)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                MainTabView()
                    .colorTheme(isDarkMode ? .dark : .light)
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
