import SwiftUI
import SwiftData

// MARK: - Filtered Moments List View
// Shows a list of moments filtered by a specific tag
// Simple, idiomatic SwiftUI with @Query

struct FilteredMomentsListView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let tag: String
    let viewModel: MomentsListViewModel?

    // Query all moments, sorted by date
    @Query(sort: \Moment.happenedAt, order: .reverse)
    private var allMoments: [Moment]

    @State private var selectedMomentId: UUID?
    @State private var showMomentDetail = false

    init(tag: String, viewModel: MomentsListViewModel? = nil) {
        self.tag = tag
        self.viewModel = viewModel
    }

    // Filter moments by tag
    private var filteredMoments: [Moment] {
        allMoments.filter { !$0.isDeleted && $0.tags.contains(tag) }
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
                .navigationTitle("#\(tag.replacingOccurrences(of: "_", with: " "))")
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
                            filterTag: tag,
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
