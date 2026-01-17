import SwiftUI
import SwiftData

// MARK: - Moment Detail Sheet
// Bottom sheet that displays full moment details with praise
// Includes action buttons for favorite and delete
// Supports swipe navigation between moments
// Can filter by tag or show all moments

struct MomentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let initialMomentId: UUID
    let filterTag: String?  // nil = show all moments, value = filter by tag
    let viewModel: MomentsListViewModel?

    // Query all moments, sorted by date
    @Query(sort: \Moment.happenedAt, order: .reverse)
    private var allMoments: [Moment]

    @State private var currentMomentId: UUID
    @State private var selectedTag: IdentifiableTag? = nil
    @State private var deletingMomentId: UUID? = nil

    // Wrapper to make tag identifiable for sheet presentation
    private struct IdentifiableTag: Identifiable {
        let id = UUID()
        let value: String
    }

    init(
        initialMomentId: UUID,
        filterTag: String? = nil,
        viewModel: MomentsListViewModel? = nil
    ) {
        self.initialMomentId = initialMomentId
        self.filterTag = filterTag
        self.viewModel = viewModel

        _currentMomentId = State(initialValue: initialMomentId)
    }

    // Get or create viewModel for child operations
    private var effectiveViewModel: MomentsListViewModel {
        if let viewModel = viewModel {
            return viewModel
        }

        // Create temporary ViewModel for child sheets
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        let momentService = MomentService(apiClient: DefaultAPIClient(), repository: repository)
        return MomentsListViewModel(momentService: momentService, repository: repository)
    }

    // Filter moments by tag if provided
    private var displayMoments: [Moment] {
        let moments = allMoments.filter { !$0.isDeleted }

        if let tag = filterTag {
            return moments.filter { $0.tags.contains(tag) }
        }
        return moments
    }

    // Current moment based on selected ID
    private var currentMoment: Moment? {
        displayMoments.first { $0.clientId == currentMomentId }
    }

    // Current index for display purposes
    private var currentIndex: Int {
        displayMoments.firstIndex { $0.clientId == currentMomentId } ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background
                CosmicBackgroundView()
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TabView for swipe navigation (content only, no buttons)
                    TabView(selection: $currentMomentId) {
                        ForEach(displayMoments) { moment in
                            MomentDetailContent(
                                moment: moment,
                                viewModel: effectiveViewModel,
                                isDeleting: deletingMomentId == moment.clientId
                            )
                            .id(moment.id)  // Force recreation when moment changes
                            .tag(moment.clientId)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .never))

                    // Fixed action buttons (stay in place during swipe)
                    VStack(spacing: 0) {
                        // Gradient fade
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color(red: 0.06, green: 0.07, blue: 0.11).opacity(0.95)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 20)

                        ActionButtonRow(
                            primaryTitle: "Nice",
                            isHugged: currentMoment?.isFavorite ?? false,
                            showDelete: true,
                            onPrimary: {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                dismiss()
                            },
                            onHug: {
                                guard let moment = currentMoment else { return }
                                Task { await effectiveViewModel.toggleFavorite(moment) }
                            },
                            onDelete: {
                                // Delete with undo support
                                print("🗑️ Delete button tapped")
                                guard let moment = currentMoment else {
                                    print("❌ No current moment to delete")
                                    return
                                }

                                let momentId = moment.clientId
                                let serverId = moment.serverId
                                let momentText = moment.text
                                print("🗑️ Deleting moment: \(momentId)")

                                // Mark as deleting for UI feedback
                                deletingMomentId = momentId

                                Task { @MainActor in
                                    do {
                                        // Delete locally
                                        modelContext.delete(moment)
                                        try modelContext.save()
                                        print("✅ Moment deleted from SwiftData")

                                        // Delete from server if synced
                                        if let serverId = serverId {
                                            try? await effectiveViewModel.momentService.deleteMoment(
                                                clientId: momentId,
                                                serverId: serverId
                                            )
                                        }

                                        // Show undo toast with restore capability
                                        ToastService.shared.showDeleted("Moment", undoAction: {
                                            guard let serverId = serverId else {
                                                print("⚠️ Cannot undo: moment not synced to server")
                                                ToastService.shared.showError("Cannot undo unsynced moment")
                                                return
                                            }

                                            Task { @MainActor in
                                                do {
                                                    print("♻️ Restoring moment: \(serverId)")
                                                    _ = try await effectiveViewModel.momentService.restoreMoment(serverId: serverId)

                                                    // Refresh the list to show the restored moment immediately
                                                    await effectiveViewModel.refresh()

                                                    ToastService.shared.showSuccess("Moment restored")
                                                } catch {
                                                    print("❌ Restore failed: \(error)")
                                                    ToastService.shared.showError("Failed to restore moment")
                                                }
                                            }
                                        })

                                        // Dismiss sheet after short delay
                                        try? await Task.sleep(nanoseconds: 100_000_000)
                                        dismiss()
                                    } catch {
                                        print("❌ Delete failed: \(error)")
                                        deletingMomentId = nil
                                        ToastService.shared.showError("Failed to delete moment")
                                    }
                                }
                            }
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                        .background(Color(red: 0.06, green: 0.07, blue: 0.11))
                    }
                }
                .opacity(deletingMomentId != nil ? 0 : 1)
                .animation(.easeOut(duration: 0.2), value: deletingMomentId)
            }
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
            .onChange(of: currentMomentId) { oldValue, newValue in
                // Haptic feedback on swipe
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
}

// MARK: - Moment Detail Content
// Extracted content view for each moment in the TabView
// Creates its own ViewModel lazily when needed

private struct MomentDetailContent: View {
    @Bindable var moment: Moment
    let viewModel: MomentsListViewModel
    let isDeleting: Bool

    // Query all moments for tag filtering
    @Query(sort: \Moment.happenedAt, order: .reverse)
    private var allMoments: [Moment]

    @State private var detailViewModel: MomentDetailViewModel
    @State private var showMomentText = false
    @State private var showPraise = false
    @State private var showTags = false
    @State private var selectedTag: IdentifiableTag? = nil
    @State private var contentOpacity: Double = 0

    init(
        moment: Moment,
        viewModel: MomentsListViewModel,
        isDeleting: Bool
    ) {
        self.moment = moment
        self.viewModel = viewModel
        self.isDeleting = isDeleting

        // Create detail ViewModel for this moment
        let vm = MomentDetailViewModel(
            moment: moment,
            repository: viewModel.repository,
            onFavoriteToggle: { m in
                await viewModel.toggleFavorite(m)
            }
        )
        _detailViewModel = State(initialValue: vm)
    }

    private var timeOfDay: TimeOfDay {
        TimeOfDay(from: moment.happenedAt)
    }

    var body: some View {
        // If deleting, show empty view to prevent accessing deleted moment
        if isDeleting {
            Color.clear
        } else {
            ScrollView {
                    VStack(spacing: 32) {
                        // Moment text display (full text, no ellipsis)
                        VStack(spacing: 12) {
                            // Time-of-day icon
                            Image(systemName: timeOfDay.iconName)
                                .font(.system(size: 32))
                                .foregroundStyle(timeOfDay.accentColor)
                                .padding(.bottom, 8)

                            Text(moment.text)
                                .font(.appTitle3)
                                .foregroundStyle(.textPrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            Text(detailViewModel.timeDisplayText)
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                        }
                        .padding(.top, 24)
                        .opacity(showMomentText ? 1 : 0)

                        // Praise section
                        VStack(spacing: 16) {
                            // Offline praise (always shown)
                            Text(moment.offlinePraise)
                                .font(.appHeadline)
                                .foregroundStyle(.textHighlightOnePrimary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)

                            // Loading indicator for AI praise (enrichment in progress)
                            if detailViewModel.isLoadingAIPraise {
                                MomentSyncLoadingView()
                                    .transition(.asymmetric(
                                        insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                        removal: .opacity.combined(with: .scale(scale: 0.8))
                                    ))
                            }

                            // AI praise (shown when available)
                            if let aiPraise = moment.praise, !aiPraise.isEmpty {
                                Text(aiPraise)
                                    .font(.appBody)
                                    .foregroundStyle(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Sync error with retry button
                            if moment.syncError != nil, !moment.isSynced {
                                VStack(spacing: 12) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.icloud.fill")
                                            .font(.system(size: 16))
                                            .foregroundStyle(.orange)
                                            .accessibilityHidden(true)

                                        Text("Not synced")
                                            .font(.appCaption)
                                            .foregroundStyle(.textSecondary)
                                    }
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Moment not synced due to limit")

                                    Button {
                                        Task {
                                            await detailViewModel.retrySyncMoment()
                                        }
                                    } label: {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.clockwise")
                                                .font(.system(size: 12, weight: .semibold))
                                            Text("Retry Sync")
                                                .font(.appCaption)
                                                .fontWeight(.semibold)
                                        }
                                        .foregroundStyle(.appPrimary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(
                                            Capsule()
                                                .strokeBorder(Color.appPrimary.opacity(0.5), lineWidth: 1)
                                        )
                                    }
                                    .accessibilityLabel("Retry syncing moment")
                                    .accessibilityHint("Double tap to try syncing this moment again")
                                }
                                .transition(.opacity)
                            }
                        }
                        .animation(.easeInOut(duration: 0.5), value: detailViewModel.isLoadingAIPraise)
                        .animation(.easeInOut(duration: 0.5), value: moment.praise)
                        .opacity(showPraise ? 1 : 0)

                        // Tags section
                        if !moment.tags.isEmpty {
                            tagsSection
                                .opacity(showTags ? 1 : 0)
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 120) // Add space for fixed action buttons
                }
                .opacity(contentOpacity)
                .onAppear {
                    startAnimations()
                }
            }
        }

    // MARK: - Animations

    private func startAnimations() {
        // Reset all animation states first
        contentOpacity = 0
        showMomentText = false
        showPraise = false
        showTags = false

        // Fade in the entire content first
        withAnimation(.easeIn(duration: 0.3)) {
            contentOpacity = 1
        }

        // Start sequential animations for individual elements
        withAnimation(.easeIn(duration: 0.6).delay(0.1)) {
            showMomentText = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.4)) {
            showPraise = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.7)) {
            showTags = true
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(moment.tags.enumerated()), id: \.offset) { index, tag in
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        selectedTag = IdentifiableTag(value: tag)
                    } label: {
                        Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                            .font(.appCaption)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.appSecondary.opacity(0.6))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(item: $selectedTag) { identifiableTag in
            // Open filtered list view for the tapped tag
            FilteredMomentsListView(
                tag: identifiableTag.value,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Preview

#Preview("Moment Detail Sheet") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Moment.self, configurations: config)
    let context = container.mainContext

    let moment1 = Moment(
        text: "I finally cleaned my desk after three weeks",
        submittedAt: Date(),
        happenedAt: Date().addingTimeInterval(-3600),
        timezone: TimeZone.current.identifier,
        timeAgo: 3600,
        offlinePraise: "Nice. You're making moves."
    )
    moment1.praise = "That's awesome! Taking care of your space is taking care of yourself."
    moment1.tags = ["self_care", "productivity"]

    let moment2 = Moment(
        text: "Called my mom today. She appreciated it.",
        submittedAt: Date().addingTimeInterval(-7200),
        happenedAt: Date().addingTimeInterval(-7200),
        timezone: TimeZone.current.identifier,
        timeAgo: 7200,
        offlinePraise: "Look at you showing up."
    )
    moment2.praise = "Family connections matter. You made someone's day better."
    moment2.tags = ["family", "connection"]
    moment2.isFavorite = true

    let moment3 = Moment(
        text: "Went for a walk instead of doom scrolling",
        submittedAt: Date().addingTimeInterval(-10800),
        happenedAt: Date().addingTimeInterval(-10800),
        timezone: TimeZone.current.identifier,
        timeAgo: 10800,
        offlinePraise: "That's it. Small stuff adds up."
    )
    moment3.tags = ["self_care", "health"]

    let moments = [moment1, moment2, moment3]
    moments.forEach { context.insert($0) }

    let repository = SwiftDataMomentRepository(modelContext: context)
    let momentService = MomentService(apiClient: DefaultAPIClient(), repository: repository)
    let viewModel = MomentsListViewModel(
        momentService: momentService,
        repository: repository
    )
    viewModel.moments = moments

    return MomentDetailSheet(
        initialMomentId: moment1.clientId,
        filterTag: nil,
        viewModel: viewModel
    )
    .preferredColorScheme(.dark)
    .modelContainer(container)
}
