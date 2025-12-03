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
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0
    @State private var momentsViewModel: MomentsListViewModel?
    @State private var journeyViewModel: JourneyViewModel?
    @State private var profileViewModel: ProfileViewModel?

    // Paywall presentation
    private var paywallService = PaywallService.shared
    @State private var paywallViewModel: PaywallViewModel?

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

            Group {
                if let viewModel = journeyViewModel {
                    JourneyView(viewModel: viewModel)
                } else {
                    Color.clear
                        .onAppear {
                            journeyViewModel = viewModelFactory.makeJourneyViewModel()
                        }
                }
            }
            .tabItem {
                Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
            }
            .tag(2)

            Group {
                if let viewModel = profileViewModel {
                    ProfileView(viewModel: viewModel)
                } else {
                    Color.clear
                        .onAppear {
                            profileViewModel = viewModelFactory.makeProfileViewModel()
                        }
                }
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(3)
        }
        .tint(Color.appPrimary)
        .onChange(of: selectedTab) { _, _ in
            tabFeedback.impactOccurred()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                Task {
                    await SubscriptionService.shared.refreshSubscriptionStatus()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .onAppear {
            if momentsViewModel == nil {
                momentsViewModel = viewModelFactory.makeMomentsListViewModel()
            }
            if journeyViewModel == nil {
                journeyViewModel = viewModelFactory.makeJourneyViewModel()
            }
            if profileViewModel == nil {
                profileViewModel = viewModelFactory.makeProfileViewModel()
            }
            if paywallViewModel == nil {
                paywallViewModel = viewModelFactory.makePaywallViewModel()
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { paywallService.shouldShowPaywall },
            set: { paywallService.shouldShowPaywall = $0 }
        )) {
            if let viewModel = paywallViewModel {
                PaywallView(viewModel: viewModel) {
                    paywallService.dismissPaywall()
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
