//
//  ContentView.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

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
                .starfieldBackground()
                .tabItem {
                    Label("Moments", systemImage: "list.bullet")
                }
                .tag(1)

            // TODO: JourneyView
            Text("Journey")
                .font(.appTitle)
                .starfieldBackground()
                .tabItem {
                    Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
        }
        .tint(Color.appPrimary)
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
