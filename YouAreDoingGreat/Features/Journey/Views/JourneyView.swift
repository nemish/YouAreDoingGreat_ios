import SwiftUI

// MARK: - Journey View
// Timeline view showing user's journey through days with moments

struct JourneyView: View {
    @State private var viewModel: JourneyViewModel

    init(viewModel: JourneyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    /// Checks if this is a new journey (only one INPROGRESS item)
    private var isJourneyJustStarted: Bool {
        viewModel.items.count == 1 && viewModel.items.first?.state == .inProgress
    }

    /// Checks if first item is FINALISED (no INPROGRESS today item exists yet)
    private var needsArtificialTodayMarker: Bool {
        guard let firstItem = viewModel.items.first else { return false }
        return firstItem.state == .finalised
    }

    /// Checks if any day has a summary (text from AI)
    private var hasAnySummary: Bool {
        viewModel.items.contains { item in
            if let text = item.text {
                return !text.isEmpty
            }
            return false
        }
    }

    /// Description text based on timeline state
    private var timelineDescriptionText: String? {
        guard !viewModel.items.isEmpty else { return nil }

        if hasAnySummary {
            return NSLocalizedString("journey_description_has_summaries", comment: "")
        } else {
            return NSLocalizedString("journey_description_no_summaries", comment: "")
        }
    }

    private var itemsWithMarkers: [TimelineItem] {
        var result: [TimelineItem] = []
        let formatter = ISO8601DateFormatter()

        // If first item is FINALISED, add artificial "You are here" marker for today
        if needsArtificialTodayMarker {
            let todayMarker = DaySummaryDTO(
                id: "__today__",
                date: formatter.string(from: Date()),
                text: nil,
                tags: [],
                momentsCount: 0,
                timesOfDay: [],
                state: .inProgress,
                createdAt: formatter.string(from: Date())
            )
            result.append(.today(todayMarker))
        }

        // Process timeline items
        for (index, item) in viewModel.items.enumerated() {
            // INPROGRESS items are rendered as "You are here" (today marker)
            if item.state == .inProgress {
                result.append(.today(item))
            } else {
                // Skip the very last item if it's empty (has no moments)
                if index == viewModel.items.count - 1 && item.momentsCount == 0 {
                    continue
                }
                result.append(.day(item))
            }
        }

        // Add "Journey begins" marker at the bottom if there are items
        // Use "Today" if journey just started (single INPROGRESS item)
        // Don't show if timeline is restricted (banner will be shown instead)
        if !viewModel.items.isEmpty && !viewModel.isTimelineRestricted {
            let beginningMarker = DaySummaryDTO(
                id: "__beginning__",
                date: isJourneyJustStarted ? formatter.string(from: Date()) : (viewModel.items.last?.date ?? formatter.string(from: Date())),
                text: nil,
                tags: [],
                momentsCount: 0,
                timesOfDay: [],
                state: .finalised,
                createdAt: formatter.string(from: Date())
            )
            result.append(.beginning(beginningMarker, isJourneyStart: isJourneyJustStarted))
        }

        return result
    }

    enum TimelineItem: Identifiable {
        case today(DaySummaryDTO)
        case day(DaySummaryDTO)
        case beginning(DaySummaryDTO, isJourneyStart: Bool)

        var id: String {
            switch self {
            case .today(let item), .day(let item), .beginning(let item, _):
                return item.id
            }
        }

        var daySummary: DaySummaryDTO {
            switch self {
            case .today(let item), .day(let item), .beginning(let item, _):
                return item
            }
        }

        var isJourneyStart: Bool {
            if case .beginning(_, let isStart) = self {
                return isStart
            }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                LinearGradient.cosmic
                    .ignoresSafeArea()

                // Content
                if viewModel.isInitialLoading && viewModel.items.isEmpty {
                    loadingView
                } else if viewModel.items.isEmpty {
                    emptyStateView
                } else {
                    timelineList
                }
            }
            .navigationTitle("Journey")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadTimeline()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
            // Timeline Restriction Alert
            .alert(
                NSLocalizedString("timeline_restriction_alert_title", comment: ""),
                isPresented: $viewModel.showTimelineRestrictedPopup
            ) {
                Button(NSLocalizedString("timeline_restriction_alert_upgrade_button", comment: "")) {
                    PaywallService.shared.showPaywallForTimelineRestriction()
                }
                Button(NSLocalizedString("timeline_restriction_alert_cancel_button", comment: ""), role: .cancel) { }
            } message: {
                Text(NSLocalizedString("timeline_restriction_alert_message_journey", comment: ""))
            }
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(itemsWithMarkers) { item in
                    switch item {
                    case .today(let daySummary):
                        TimelineItemView(
                            item: daySummary,
                            isToday: true,
                            isBeginning: false,
                            isJourneyStart: false,
                            descriptionText: timelineDescriptionText
                        )
                    case .day(let daySummary):
                        TimelineItemView(
                            item: daySummary,
                            isToday: false,
                            isBeginning: false,
                            isJourneyStart: false
                        )
                    case .beginning(let daySummary, let isJourneyStart):
                        TimelineItemView(
                            item: daySummary,
                            isToday: false,
                            isBeginning: true,
                            isJourneyStart: isJourneyStart
                        )
                    }
                }

                // Show loading indicator or restriction banner
                if viewModel.canLoadMore {
                    loadMoreView
                        .onAppear {
                            Task { await viewModel.loadNextPage() }
                        }
                } else if viewModel.isTimelineRestricted {
                    // Show the restriction banner at the end of the timeline
                    TimelineRestrictedBanner {
                        PaywallService.shared.showPaywallForTimelineRestriction()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Supporting Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            Text("Loading your journey...")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
            ProgressView()
                .scaleEffect(1.2)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.appPrimary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appPrimary,
                                Color.appPrimary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 64, height: 64)

                Image(systemName: "map")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Your journey starts here")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("Log your first moment to begin tracking your journey.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var loadMoreView: some View {
        HStack {
            Spacer()
            if viewModel.isLoadingMore {
                ProgressView()
                    .tint(.appPrimary)
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

// MARK: - Previews

#Preview("Journey - With Timeline") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)

    // Mock data
    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    let mockItems = [
        DaySummaryDTO(
            id: "0",
            date: formatter.string(from: now),
            text: nil,
            tags: [],
            momentsCount: 2,
            timesOfDay: ["cloud-sun"],
            state: .inProgress,
            createdAt: formatter.string(from: now)
        ),
        DaySummaryDTO(
            id: "1",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
            text: "Had a productive morning work session. Called my mom to check in.",
            tags: ["work", "family", "connection"],
            momentsCount: 2,
            timesOfDay: ["cloud-sun", "sunset"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
        ),
        DaySummaryDTO(
            id: "2",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!),
            text: "Went for a walk in the sunshine. Read a few chapters before bed.",
            tags: ["exercise", "outdoors", "self-care"],
            momentsCount: 3,
            timesOfDay: ["sun.max", "moon"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!)
        ),
        DaySummaryDTO(
            id: "3",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!),
            text: nil,
            tags: [],
            momentsCount: 0,
            timesOfDay: [],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!)
        ),
    ]

    viewModel.items = mockItems

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Journey - Empty State") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Journey - Loading") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)
    viewModel.isInitialLoading = true

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Journey - No INPROGRESS Today") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)

    // Mock data: No moments submitted today, so no INPROGRESS item exists
    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    let mockItems = [
        // First item is FINALISED (yesterday), no INPROGRESS for today
        DaySummaryDTO(
            id: "1",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
            text: "Had a productive morning work session. Called my mom to check in.",
            tags: ["work", "family", "connection"],
            momentsCount: 2,
            timesOfDay: ["cloud-sun", "sunset"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
        ),
        DaySummaryDTO(
            id: "2",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!),
            text: "Went for a walk in the sunshine.",
            tags: ["exercise", "outdoors"],
            momentsCount: 1,
            timesOfDay: ["sun.max"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!)
        ),
    ]

    viewModel.items = mockItems

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Journey - Timeline Restricted (Banner)") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)

    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    // Create 14 days of mock data to simulate hitting the limit
    var mockItems: [DaySummaryDTO] = []

    // Today (INPROGRESS)
    mockItems.append(DaySummaryDTO(
        id: "0",
        date: formatter.string(from: now),
        text: nil,
        tags: [],
        momentsCount: 1,
        timesOfDay: ["cloud-sun"],
        state: .inProgress,
        createdAt: formatter.string(from: now)
    ))

    // Past 14 days
    for i in 1...14 {
        mockItems.append(DaySummaryDTO(
            id: "\(i)",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -i, to: now)!),
            text: "Day \(i) summary - Some great moments happened.",
            tags: ["daily", "wins"],
            momentsCount: i % 3 + 1,
            timesOfDay: ["sun.max"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -i, to: now)!)
        ))
    }

    viewModel.items = mockItems
    viewModel.isTimelineRestricted = true

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}

#Preview("Journey - Timeline Restricted (Popup)") {
    let apiClient = DefaultAPIClient()
    let viewModel = JourneyViewModel(apiClient: apiClient)

    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    let mockItems = [
        DaySummaryDTO(
            id: "0",
            date: formatter.string(from: now),
            text: nil,
            tags: [],
            momentsCount: 2,
            timesOfDay: ["cloud-sun"],
            state: .inProgress,
            createdAt: formatter.string(from: now)
        ),
        DaySummaryDTO(
            id: "1",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
            text: "Had a productive day.",
            tags: ["work"],
            momentsCount: 2,
            timesOfDay: ["cloud-sun", "sunset"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
        ),
    ]

    viewModel.items = mockItems
    viewModel.isTimelineRestricted = true
    viewModel.showTimelineRestrictedPopup = true

    return JourneyView(viewModel: viewModel)
        .preferredColorScheme(.dark)
}
