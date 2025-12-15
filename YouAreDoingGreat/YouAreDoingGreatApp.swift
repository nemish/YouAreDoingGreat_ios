//
//  YouAreDoingGreatApp.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI
import SwiftData
import RevenueCat

@main
struct YouAreDoingGreatApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        configureRevenueCat()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .preferredColorScheme(.dark) // Force dark mode for v1
                        .transition(.opacity)
                        .zIndex(1)
                } else {
                    WelcomeView {
                        completeOnboarding()
                    }
                    .preferredColorScheme(.dark) // Force dark mode for v1
                    .transition(.opacity)
                    .zIndex(0)
                }
            }
            .animation(.easeOut(duration: 1.0), value: hasCompletedOnboarding)
        }
        .modelContainer(for: Moment.self)
    }

    private func completeOnboarding() {
        // State change triggers the .animation modifier on ZStack
        // No need for withAnimation here - it causes double animation conflict
        hasCompletedOnboarding = true
    }

    private func configureRevenueCat() {
        Purchases.logLevel = AppConfig.isDebugBuild ? .debug : .error

        let userID = UserIDProvider.shared.userID

        Purchases.configure(
            with: .builder(withAPIKey: AppConfig.revenueCatAPIKey)
                .with(appUserID: userID)
                .build()
        )

        // Refresh subscription status (also ensures correct user ID)
        Task { @MainActor in
            await SubscriptionService.shared.refreshSubscriptionStatus()
        }
    }
}
