import SwiftUI
import SwiftData

// MARK: - Moment Detail Sheet
// Bottom sheet that displays full moment details with praise
// Includes action buttons for favorite and delete
// Supports swipe navigation between moments

struct MomentDetailSheet: View {
    @Environment(\.dismiss) private var dismiss

    let moments: [Moment]
    let initialIndex: Int
    let repository: MomentRepository
    let onFavoriteToggle: (Moment) async -> Void
    let onDelete: (Moment) async -> Void

    @State private var currentIndex: Int

    init(
        moments: [Moment],
        initialIndex: Int,
        repository: MomentRepository,
        onFavoriteToggle: @escaping (Moment) async -> Void,
        onDelete: @escaping (Moment) async -> Void
    ) {
        self.moments = moments
        self.initialIndex = initialIndex
        self.repository = repository
        self.onFavoriteToggle = onFavoriteToggle
        self.onDelete = onDelete

        _currentIndex = State(initialValue: initialIndex)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Cosmic background
                CosmicBackgroundView()
                    .ignoresSafeArea()

                // TabView for swipe navigation with lazy ViewModel creation
                TabView(selection: $currentIndex) {
                    ForEach(Array(moments.enumerated()), id: \.element.id) { index, moment in
                        MomentDetailContent(
                            moment: moment,
                            repository: repository,
                            onFavoriteToggle: onFavoriteToggle,
                            onDelete: { deletedMoment in
                                await handleDelete(deletedMoment, at: index)
                            },
                            onDismiss: { dismiss() }
                        )
                        .id(moment.id)  // Force recreation when moment changes
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .indexViewStyle(.page(backgroundDisplayMode: .never))
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
            .onChange(of: currentIndex) { oldValue, newValue in
                // Haptic feedback on swipe
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }

    // MARK: - Delete Handling

    private func handleDelete(_ moment: Moment, at index: Int) async {
        // Dismissal is now handled by the child view before calling this
        await onDelete(moment)
    }
}

// MARK: - Moment Detail Content
// Extracted content view for each moment in the TabView
// Creates its own ViewModel lazily when needed

private struct MomentDetailContent: View {
    @Bindable var moment: Moment
    let repository: MomentRepository
    let onFavoriteToggle: (Moment) async -> Void
    let onDelete: (Moment) async -> Void
    let onDismiss: () -> Void

    @State private var viewModel: MomentDetailViewModel
    @State private var showMomentText = false
    @State private var showPraise = false
    @State private var showTags = false
    @State private var showButtons = false
    @State private var showDeleteConfirmation = false
    @State private var selectedTag: IdentifiableTag? = nil
    @State private var contentOpacity: Double = 0

    init(
        moment: Moment,
        repository: MomentRepository,
        onFavoriteToggle: @escaping (Moment) async -> Void,
        onDelete: @escaping (Moment) async -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.moment = moment
        self.repository = repository
        self.onFavoriteToggle = onFavoriteToggle
        self.onDelete = onDelete
        self.onDismiss = onDismiss

        // Create ViewModel lazily only when this view is instantiated
        let vm = MomentDetailViewModel(
            moment: moment,
            repository: repository,
            onFavoriteToggle: onFavoriteToggle,
            onDelete: onDelete
        )
        _viewModel = State(initialValue: vm)
    }

    private var timeOfDay: TimeOfDay {
        TimeOfDay(from: moment.happenedAt)
    }

    var body: some View {
        VStack(spacing: 0) {
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

                        Text(viewModel.timeDisplayText)
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
                        if viewModel.isLoadingAIPraise {
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
                                        await viewModel.retrySyncMoment()
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
                    .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingAIPraise)
                    .animation(.easeInOut(duration: 0.5), value: moment.praise)
                    .opacity(showPraise ? 1 : 0)

                    // Tags section
                    if !moment.tags.isEmpty {
                        tagsSection
                            .opacity(showTags ? 1 : 0)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 120) // Add space for action buttons
            }

            // Action buttons fixed at bottom
            VStack(spacing: 0) {
                // Gradient fade for better visual separation
                LinearGradient(
                    colors: [
                        Color.clear,
                        Color(red: 0.06, green: 0.07, blue: 0.11).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                    .background(Color(red: 0.06, green: 0.07, blue: 0.11))
                    .opacity(showButtons ? 1 : 0)
            }
        }
        .opacity(contentOpacity)
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animations

    private func startAnimations() {
        // Reset all animation states first
        contentOpacity = 0
        showMomentText = false
        showPraise = false
        showTags = false
        showButtons = false

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

        withAnimation(.easeIn(duration: 0.6).delay(1.0)) {
            showButtons = true
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
            FilteredMomentsSheet(tag: identifiableTag.value)
        }
    }

    private var actionButtons: some View {
        ActionButtonRow(
            primaryTitle: "Nice",
            isHugged: moment.isFavorite,
            showDelete: true,
            onPrimary: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDismiss()
            },
            onHug: {
                Task { await viewModel.toggleHug() }
            },
            onDelete: {
                showDeleteConfirmation = true
            }
        )
        .confirmationDialog(
            "Delete this moment?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                // Capture moment reference before dismissing
                let momentToDelete = moment

                // Dismiss immediately to avoid SwiftUI updating views with deleted objects
                onDismiss()

                // Perform deletion in background after dismissal
                Task {
                    await onDelete(momentToDelete)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
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
    context.insert(moment1)

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
    context.insert(moment2)

    let moment3 = Moment(
        text: "Went for a walk instead of doom scrolling",
        submittedAt: Date().addingTimeInterval(-10800),
        happenedAt: Date().addingTimeInterval(-10800),
        timezone: TimeZone.current.identifier,
        timeAgo: 10800,
        offlinePraise: "That's it. Small stuff adds up."
    )
    moment3.tags = ["self_care", "health"]
    context.insert(moment3)

    let repository = SwiftDataMomentRepository(modelContext: context)
    let moments = [moment1, moment2, moment3]

    return MomentDetailSheet(
        moments: moments,
        initialIndex: 0,
        repository: repository,
        onFavoriteToggle: { _ in },
        onDelete: { _ in }
    )
    .preferredColorScheme(.dark)
    .modelContainer(container)
}
