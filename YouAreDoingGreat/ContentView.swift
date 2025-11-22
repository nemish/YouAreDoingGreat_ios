//
//  ContentView.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    // Haptic feedback for tab switch
    private let tabFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // TODO: MomentsListView
            Text("Moments")
                .font(.appTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient.cosmic.ignoresSafeArea())
                .tabItem {
                    Label("Moments", systemImage: "list.bullet")
                }
                .tag(1)

            // TODO: JourneyView
            Text("Journey")
                .font(.appTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LinearGradient.cosmic.ignoresSafeArea())
                .tabItem {
                    Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .tint(Color.appPrimary)
        .onChange(of: selectedTab) { _, _ in
            tabFeedback.impactOccurred()
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
