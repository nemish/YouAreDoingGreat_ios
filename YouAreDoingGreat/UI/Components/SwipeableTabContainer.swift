//
//  SwipeableTabContainer.swift
//  YouAreDoingGreat
//
//  View modifier that adds horizontal swipe gesture navigation between tabs
//

import SwiftUI

/// View modifier that enables swipe gestures for tab navigation
struct SwipeableTabModifier: ViewModifier {
    @Binding var selectedTab: Int
    let totalTabs: Int

    // Gesture thresholds
    private let dragThreshold: CGFloat = 50
    private let velocityThreshold: CGFloat = 100

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = abs(value.translation.height)
                        let velocity = value.predictedEndTranslation.width - value.translation.width

                        // Only process if horizontal movement is dominant
                        guard abs(horizontalAmount) > verticalAmount * 1.5 else {
                            return
                        }

                        // Determine if we should switch tabs based on drag distance or velocity
                        let shouldSwitchTab = abs(horizontalAmount) > dragThreshold ||
                                              abs(velocity) > velocityThreshold

                        if shouldSwitchTab {
                            if horizontalAmount > 0 && selectedTab > 0 {
                                // Swipe right -> previous tab (left)
                                selectedTab -= 1
                            } else if horizontalAmount < 0 && selectedTab < totalTabs - 1 {
                                // Swipe left -> next tab (right)
                                selectedTab += 1
                            }
                        }
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// Adds swipe gesture navigation for tab switching
    /// - Parameters:
    ///   - selectedTab: Binding to the currently selected tab index
    ///   - totalTabs: Total number of tabs available
    /// - Returns: Modified view with swipe gesture support
    func swipeableTab(selectedTab: Binding<Int>, totalTabs: Int) -> some View {
        modifier(SwipeableTabModifier(selectedTab: selectedTab, totalTabs: totalTabs))
    }
}

// MARK: - Preview

#Preview("Swipeable Tabs") {
    struct PreviewContainer: View {
        @State private var selectedTab = 0

        var body: some View {
            TabView(selection: $selectedTab) {
                ZStack {
                    Color.blue.opacity(0.3)
                    VStack {
                        Text("Home Tab")
                            .font(.largeTitle)
                        Text("Swipe left to go to Moments")
                            .foregroundStyle(.secondary)
                        Text("Current: \(selectedTab)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

                ZStack {
                    Color.green.opacity(0.3)
                    VStack {
                        Text("Moments Tab")
                            .font(.largeTitle)
                        Text("Swipe left/right to navigate")
                            .foregroundStyle(.secondary)
                        Text("Current: \(selectedTab)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tabItem {
                    Label("Moments", systemImage: "list.bullet")
                }
                .tag(1)

                ZStack {
                    Color.purple.opacity(0.3)
                    VStack {
                        Text("Journey Tab")
                            .font(.largeTitle)
                        Text("Swipe left/right to navigate")
                            .foregroundStyle(.secondary)
                        Text("Current: \(selectedTab)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tabItem {
                    Label("Journey", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)

                ZStack {
                    Color.orange.opacity(0.3)
                    VStack {
                        Text("Profile Tab")
                            .font(.largeTitle)
                        Text("Swipe right to go to Journey")
                            .foregroundStyle(.secondary)
                        Text("Current: \(selectedTab)")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
            }
            .tint(.orange)
            .swipeableTab(selectedTab: $selectedTab, totalTabs: 4)
        }
    }

    return PreviewContainer()
        .preferredColorScheme(.dark)
}
