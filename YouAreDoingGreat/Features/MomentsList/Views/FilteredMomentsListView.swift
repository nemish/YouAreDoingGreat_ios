import SwiftUI
import SwiftData

// MARK: - Constants

private let scrollCollapseThreshold: CGFloat = -50

// MARK: - Filter Type
// Defines the type of filter to apply to moments

enum MomentsFilter {
    case tag(String)
    case date(Date, daySummary: DaySummaryDTO?)

    var title: String {
        switch self {
        case .tag(let tag):
            return "#\(tag.replacingOccurrences(of: "_", with: " "))"
        case .date(let date, _):
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMMM d"
            return formatter.string(from: date)
        }
    }

    var daySummary: DaySummaryDTO? {
        if case .date(_, let summary) = self {
            return summary
        }
        return nil
    }
}

// MARK: - Filtered Moments List View
// Shows a list of moments filtered by tag or date
// Simple, idiomatic SwiftUI with @Query

struct FilteredMomentsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let filter: MomentsFilter
    let viewModel: MomentsListViewModel?

    // Query all moments, sorted by date
    @Query(sort: \Moment.happenedAt, order: .reverse)
    private var allMoments: [Moment]

    @State private var selectedMomentId: UUID?
    @State private var showMomentDetail = false
    @State private var scrollOffset: CGFloat = 0
    @State private var isPanelCollapsed = false
    @State private var selectedTag: IdentifiableTag? = nil

    // Wrapper to make tag identifiable for sheet presentation
    private struct IdentifiableTag: Identifiable {
        let id = UUID()
        let value: String
    }

    init(tag: String, viewModel: MomentsListViewModel? = nil) {
        self.filter = .tag(tag)
        self.viewModel = viewModel
    }

    init(date: Date, daySummary: DaySummaryDTO? = nil, viewModel: MomentsListViewModel? = nil) {
        self.filter = .date(date, daySummary: daySummary)
        self.viewModel = viewModel
    }

    init(filter: MomentsFilter, viewModel: MomentsListViewModel? = nil) {
        self.filter = filter
        self.viewModel = viewModel
    }

    // Filter moments by tag or date
    private var filteredMoments: [Moment] {
        switch filter {
        case .tag(let tag):
            return allMoments.filter { $0.tags.contains(tag) }
        case .date(let date, _):
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
                return []
            }
            return allMoments.filter { moment in
                moment.happenedAt >= startOfDay &&
                moment.happenedAt < endOfDay
            }
        }
    }

    // Show info panel only for date filters
    private var showInfoPanel: Bool {
        if case .date = filter {
            return filter.daySummary != nil
        }
        return false
    }

    // Get tag for detail sheet (if filtering by tag)
    private var filterTag: String? {
        if case .tag(let tag) = filter {
            return tag
        }
        return nil
    }

    // Get or create viewModel for detail sheet
    private var effectiveViewModel: MomentsListViewModel {
        if let viewModel = viewModel {
            return viewModel
        }

        // Create temporary ViewModel
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        let momentService = MomentService(apiClient: DefaultAPIClient(), repository: repository)
        return MomentsListViewModel(momentService: momentService, repository: repository)
    }

    var body: some View {
        ZStack {
            NavigationStack {
                ZStack {
                    // Cosmic background
                    CosmicBackgroundView()
                        .ignoresSafeArea()

                    if filteredMoments.isEmpty {
                        emptyState
                    } else {
                        momentsList
                    }
                }
                .navigationTitle(filter.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.textSecondary)
                        }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
                .sheet(isPresented: $showMomentDetail) {
                    if let momentId = selectedMomentId {
                        MomentDetailSheet(
                            initialMomentId: momentId,
                            filterTag: filterTag,
                            viewModel: effectiveViewModel
                        )
                        .toastContainer()  // Add toast support to detail sheet
                    }
                }
            }
        }
        .toastContainer()  // Add toast support to filtered list
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "tag")
                .font(.system(size: 48))
                .foregroundStyle(.textTertiary)

            Text("No moments with this tag yet")
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)
        }
    }

    private var momentsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Info panel for date filters
                if showInfoPanel, let daySummary = filter.daySummary {
                    DayInfoPanel(
                        daySummary: daySummary,
                        isCollapsed: isPanelCollapsed,
                        onTagTap: { tag in
                            selectedTag = IdentifiableTag(value: tag)
                        }
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isPanelCollapsed)
                    .padding(.bottom, 12)
                }

                // Moments list
                VStack(spacing: 12) {
                    ForEach(filteredMoments) { moment in
                        MomentCard(
                            moment: moment,
                            isHighlighted: false,
                            viewModel: effectiveViewModel
                        )
                        .onTapGesture {
                            selectedMomentId = moment.clientId
                            showMomentDetail = true
                        }
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                    }
                }
                .padding()
                .animation(.spring(response: 0.35, dampingFraction: 0.75), value: filteredMoments.map { $0.id })
            }
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named("scroll")).minY
                        )
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = value
            // Collapse when scroll offset exceeds threshold
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isPanelCollapsed = value < scrollCollapseThreshold
            }
        }
        .sheet(item: $selectedTag) { identifiableTag in
            // Open filtered list view for the tapped tag (across all dates)
            FilteredMomentsListView(
                tag: identifiableTag.value,
                viewModel: effectiveViewModel
            )
        }
    }

    // MARK: - Scroll Offset Preference Key

    private struct ScrollOffsetPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0

        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

// MARK: - Preview

#Preview("Filtered Moments List") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    let moment1 = Moment(
        text: "Morning meditation session",
        submittedAt: Date(),
        happenedAt: Date(),
        timezone: TimeZone.current.identifier,
        timeAgo: 0,
        offlinePraise: "Nice. You're making moves."
    )
    moment1.tags = ["self_care", "mindfulness"]

    let moment2 = Moment(
        text: "Took a walk in nature",
        submittedAt: Date().addingTimeInterval(-3600),
        happenedAt: Date().addingTimeInterval(-3600),
        timezone: TimeZone.current.identifier,
        timeAgo: 3600,
        offlinePraise: "Look at you showing up."
    )
    moment2.tags = ["self_care", "outdoors"]

    let moment3 = Moment(
        text: "Prepared healthy lunch",
        submittedAt: Date().addingTimeInterval(-7200),
        happenedAt: Date().addingTimeInterval(-7200),
        timezone: TimeZone.current.identifier,
        timeAgo: 7200,
        offlinePraise: "That's it. Small stuff adds up."
    )
    moment3.tags = ["self_care", "health"]

    [moment1, moment2, moment3].forEach { context.insert($0) }

    return FilteredMomentsListView(tag: "self_care", viewModel: nil)
        .preferredColorScheme(.dark)
        .modelContainer(container)
}
