//
//  ContentView.swift
//  YouAreDoingGreat
//
//  Created by Ярослав Мельничук on 17.11.2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var selectedTab = 0
    @State private var momentsViewModel: MomentsListViewModel?

    // Haptic feedback for tab switch
    private let tabFeedback = UIImpactFeedbackGenerator(style: .light)
    
    // ViewModel factory for dependency injection
    private var viewModelFactory: ViewModelFactory {
        ViewModelFactory(modelContext: modelContext)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            Group {
                if let viewModel = momentsViewModel {
                    MomentsListView(viewModel: viewModel)
                } else {
                    Color.clear
                        .onAppear {
                            momentsViewModel = viewModelFactory.makeMomentsListViewModel()
                        }
                }
            }
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
        .onAppear {
            if momentsViewModel == nil {
                momentsViewModel = viewModelFactory.makeMomentsListViewModel()
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
