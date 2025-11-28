import SwiftUI
import SwiftData

// MARK: - Moments List View
// Main screen displaying all user moments with date-based grouping

struct MomentsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: MomentsListViewModel

    // Haptic feedback
    private let mediumFeedback = UIImpactFeedbackGenerator(style: .medium)

    init(viewModel: MomentsListViewModel) {
        _viewModel = State(initialValue: viewModel)
        configureNavigationBarAppearance()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.cosmic
                    .ignoresSafeArea()

                // Content
                if viewModel.isInitialLoading && viewModel.moments.isEmpty {
                    loadingView
                } else if viewModel.moments.isEmpty {
                    emptyStateView
                } else {
                    momentsList
                }
            }
            .navigationTitle("Your Moments")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadMoments()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $viewModel.showMomentDetail) {
                if let moment = viewModel.selectedMomentForDetail {
                    MomentDetailSheet(
                        viewModel: MomentDetailViewModel(
                            moment: moment,
                            onFavoriteToggle: { m in
                                await viewModel.toggleFavorite(m)
                            },
                            onDelete: { m in
                                await viewModel.deleteMoment(m)
                            }
                        ),
                        moment: moment
                    )
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK") { }
            } message: {
                Text(viewModel.error ?? "An error occurred")
            }
        }
    }

    // MARK: - Moments List

    private var momentsList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.moments) { moment in
                    MomentCard(moment: moment)
                        .onTapGesture {
                            mediumFeedback.impactOccurred()
                            viewModel.showDetail(for: moment)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }

                if viewModel.canLoadMore {
                    loadMoreView
                        .onAppear {
                            Task { await viewModel.loadNextPage() }
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Supporting Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            Text("Loading your moments...")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
            ProgressView()
                .scaleEffect(1.2)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            celebrationIcon

            Text("No moments yet...")
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)

            Text("But you're here, so that's one.\nTap 'I Did a Thing' to get started.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var celebrationIcon: some View {
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

            // Star icon - celebratory, not task-completion
            Image(systemName: "sparkles")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
        }
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

    // MARK: - Navigation Bar Configuration

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = .clear

        // Large title font (Comfortaa)
        let largeTitleFont = UIFont(name: "Comfortaa-Bold", size: 34) ?? UIFont.systemFont(ofSize: 34, weight: .bold)
        appearance.largeTitleTextAttributes = [
            .font: largeTitleFont,
            .foregroundColor: UIColor.white
        ]

        // Regular title font (Comfortaa)
        let titleFont = UIFont(name: "Comfortaa-Bold", size: 17) ?? UIFont.systemFont(ofSize: 17, weight: .semibold)
        appearance.titleTextAttributes = [
            .font: titleFont,
            .foregroundColor: UIColor.white
        ]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}

// MARK: - Previews

#Preview("Moments List - With Moments") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    // Create sample moments
    let moment1 = Moment(
        text: "I installed this app. A tiny step, but it counts.",
        submittedAt: Date(),
        happenedAt: Date().addingTimeInterval(-180),
        timezone: TimeZone.current.identifier,
        timeAgo: 180,
        offlinePraise: "Nice. You're making moves."
    )
    moment1.tags = ["milestone", "solo"]
    moment1.isSynced = true

    let moment2 = Moment(
        text: "Secret",
        submittedAt: Date().addingTimeInterval(-300),
        happenedAt: Date().addingTimeInterval(-300),
        timezone: TimeZone.current.identifier,
        timeAgo: nil,
        offlinePraise: "That's it. Small stuff adds up."
    )
    moment2.tags = ["solo"]
    moment2.isSynced = true

    let moment3 = Moment(
        text: "Called my mom today. She appreciated it.",
        submittedAt: Date().addingTimeInterval(-3600),
        happenedAt: Date().addingTimeInterval(-3600),
        timezone: TimeZone.current.identifier,
        timeAgo: 3600,
        offlinePraise: "Look at you showing up."
    )
    moment3.tags = ["family", "connection"]
    moment3.isFavorite = true
    moment3.isSynced = true

    context.insert(moment1)
    context.insert(moment2)
    context.insert(moment3)

    let repository = SwiftDataMomentRepository(modelContext: context)
    let apiClient = DefaultAPIClient()
    let service = MomentService(apiClient: apiClient, repository: repository)
    let viewModel = MomentsListViewModel(momentService: service, repository: repository)

    return MomentsListView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .modelContainer(container)
}

#Preview("Moments List - Empty State") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    let repository = SwiftDataMomentRepository(modelContext: context)
    let apiClient = DefaultAPIClient()
    let service = MomentService(apiClient: apiClient, repository: repository)
    let viewModel = MomentsListViewModel(momentService: service, repository: repository)

    return MomentsListView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .modelContainer(container)
}

#Preview("Moments List - Loading") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    let repository = SwiftDataMomentRepository(modelContext: context)
    let apiClient = DefaultAPIClient()
    let service = MomentService(apiClient: apiClient, repository: repository)
    let viewModel = MomentsListViewModel(momentService: service, repository: repository)
    viewModel.isInitialLoading = true

    return MomentsListView(viewModel: viewModel)
        .preferredColorScheme(.dark)
        .modelContainer(container)
}
