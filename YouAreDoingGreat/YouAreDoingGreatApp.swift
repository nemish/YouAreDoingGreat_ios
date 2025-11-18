//
//  YouAreDoingGreatApp.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI

@main
struct YouAreDoingGreatApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .preferredColorScheme(.dark) // Force dark mode for v1
            } else {
                WelcomeView {
                    completeOnboarding()
                }
                .preferredColorScheme(.dark) // Force dark mode for v1
            }
        }
    }

    private func completeOnboarding() {
        hasCompletedOnboarding = true
    }
}
