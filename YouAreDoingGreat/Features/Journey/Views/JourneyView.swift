import SwiftUI

// MARK: - Journey View
// Timeline view showing user's journey through days with moments

struct JourneyView: View {
    @State private var viewModel: JourneyViewModel

    init(viewModel: JourneyViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    private var itemsWithMarkers: [TimelineItem] {
        var result: [TimelineItem] = []
        let formatter = ISO8601DateFormatter()

        // Always add "You are here" marker at the top
        let todayMarker = DaySummaryDTO(
            id: "__today__",
            date: formatter.string(from: Date()),
            text: nil,
            tags: [],
            momentsCount: 0,
            timesOfDay: [],
            createdAt: formatter.string(from: Date())
        )
        result.append(.today(todayMarker))

        // Add all actual timeline items (except empty days at the end)
        for item in viewModel.items {
            // Skip the very last item if it's empty (has no moments)
            if item.id == viewModel.items.last?.id && item.momentsCount == 0 {
                continue
            }
            result.append(.day(item))
        }

        // Add "Journey begins" marker at the bottom if there are items
        if !viewModel.items.isEmpty {
            let beginningMarker = DaySummaryDTO(
                id: "__beginning__",
                date: viewModel.items.last?.date ?? formatter.string(from: Date()),
                text: nil,
                tags: [],
                momentsCount: 0,
                timesOfDay: [],
                createdAt: formatter.string(from: Date())
            )
            result.append(.beginning(beginningMarker))
        }

        return result
    }

    enum TimelineItem: Identifiable {
        case today(DaySummaryDTO)
        case day(DaySummaryDTO)
        case beginning(DaySummaryDTO)

        var id: String {
            switch self {
            case .today(let item), .day(let item), .beginning(let item):
                return item.id
            }
        }

        var daySummary: DaySummaryDTO {
            switch self {
            case .today(let item), .day(let item), .beginning(let item):
                return item
            }
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
                            isBeginning: false
                        )
                    case .day(let daySummary):
                        TimelineItemView(
                            item: daySummary,
                            isToday: false,
                            isBeginning: false
                        )
                    case .beginning(let daySummary):
                        TimelineItemView(
                            item: daySummary,
                            isToday: false,
                            isBeginning: true
                        )
                    }
                }

                if viewModel.canLoadMore {
                    loadMoreView
                        .onAppear {
                            Task { await viewModel.loadNextPage() }
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
            id: "1",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
            text: "Had a productive morning work session. Called my mom to check in.",
            tags: ["work", "family", "connection"],
            momentsCount: 2,
            timesOfDay: ["cloud-sun", "sunset"],
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
        ),
        DaySummaryDTO(
            id: "2",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!),
            text: "Went for a walk in the sunshine. Read a few chapters before bed.",
            tags: ["exercise", "outdoors", "self-care"],
            momentsCount: 3,
            timesOfDay: ["sun.max", "moon"],
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -2, to: now)!)
        ),
        DaySummaryDTO(
            id: "3",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!),
            text: nil,
            tags: [],
            momentsCount: 0,
            timesOfDay: [],
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
