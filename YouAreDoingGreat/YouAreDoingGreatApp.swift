//
//  YouAreDoingGreatApp.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI
import SwiftData

@main
struct YouAreDoingGreatApp: App {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                if hasCompletedOnboarding {
                    ContentView()
                        .preferredColorScheme(.dark) // Force dark mode for v1
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                        .zIndex(1)
                } else {
                    WelcomeView {
                        completeOnboarding()
                    }
                    .preferredColorScheme(.dark) // Force dark mode for v1
                    .transition(.asymmetric(
                        insertion: .opacity,
                        removal: .opacity.combined(with: .scale(scale: 1.05))
                    ))
                    .zIndex(0)
                }
            }
            .animation(.easeInOut(duration: 0.6), value: hasCompletedOnboarding)
        }
        .modelContainer(for: Moment.self)
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}
