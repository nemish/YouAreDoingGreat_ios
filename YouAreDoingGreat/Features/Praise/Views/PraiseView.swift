import SwiftUI

// MARK: - Praise View Model Protocol
// Defines the contract for both real and mock view models

protocol PraiseViewModelProtocol: AnyObject, Observable {
    var momentText: String { get }
    var timeAgoSeconds: Int? { get }
    var offlinePraise: String { get }
    var aiPraise: String? { get set }
    var tags: [String] { get set }
    var isLoadingAIPraise: Bool { get set }
    var syncError: String? { get set }
    var showContent: Bool { get set }
    var showPraise: Bool { get set }
    var showTags: Bool { get set }
    var showButton: Bool { get set }
    var timeDisplayText: String { get }
    var clientId: UUID { get }
    var isNiceButtonDisabled: Bool { get }

    // Sync failure state
    var isLimitBlocked: Bool { get set }
    var isSyncFailed: Bool { get }

    // Hug state (maps to isFavorite)
    var isHugged: Bool { get }

    func cancelPolling()
    func startEntranceAnimation() async
    func syncMomentAndFetchPraise() async
    func retrySyncMoment() async
    func toggleHug() async
}

// MARK: - Praise Content View
// Inline praise content to be used within LogMomentView
// Dark mode only for v1

struct PraiseContentView<ViewModel: PraiseViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel
    @Binding var selectedTab: Int
    var onDismiss: () -> Void


    // Highlight service
    @State private var highlightService = HighlightService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Scrollable content area
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Top spacing
                    Spacer()
                        .frame(height: 40)

                    // Moment text display
                    VStack(spacing: 12) {
                        Text(viewModel.momentText)
                            .font(.appTitle3)
                            .foregroundStyle(.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(4)

                        Text(viewModel.timeDisplayText)
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                    }
                    .opacity(viewModel.showContent ? 1 : 0)
                    .offset(y: viewModel.showContent ? 0 : 20)

                    // Praise message with loading indicator
                    VStack(spacing: 16) {
                        // Offline praise text (always shown) with word-by-word animation
                        AnimatedTextView(
                            text: viewModel.offlinePraise,
                            font: .appHeadline,
                            foregroundStyle: Color.textHighlightOnePrimary,
                            multilineTextAlignment: .center,
                            wordDelay: 0.05
                        )

                        // Loading indicator for AI praise - fades out when praise arrives
                        if viewModel.isLoadingAIPraise {
                            MomentSyncLoadingView()
                                .transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }

                        // AI praise text with smooth word-by-word animation (no layout jumps)
                        if let aiPraise = viewModel.aiPraise, !aiPraise.isEmpty {
                            SmoothAnimatedTextView(
                                text: aiPraise,
                                font: .appBody,
                                foregroundStyle: Color.textSecondary,
                                multilineTextAlignment: .center,
                                wordDelay: 0.04
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        }

                        // Sync failure indicator with retry button
                        if viewModel.isLimitBlocked && !viewModel.isLoadingAIPraise {
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
                        // Other error message (non-limit errors)
                        else if let error = viewModel.syncError, !viewModel.isLoadingAIPraise && !viewModel.isLimitBlocked {
                            Text(error)
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                                .multilineTextAlignment(.center)
                                .transition(.opacity)
                        }
                    }
                    .opacity(viewModel.showPraise ? 1 : 0)
                    .offset(y: viewModel.showPraise ? 0 : 10)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.isLoadingAIPraise)
                    .animation(.easeInOut(duration: 0.4), value: viewModel.aiPraise != nil)

                    // Tags section
                    if !viewModel.tags.isEmpty {
                        tagsSection
                            .opacity(viewModel.showTags ? 1 : 0)
                            .offset(y: viewModel.showTags ? 0 : 10)
                            .padding(.bottom, 24)
                    }
                }
                .padding(.horizontal, 32)
            }

            // Action buttons: Nice (fills width) + Hug (icon)
            ActionButtonRow(
                primaryTitle: "Nice",
                isHugged: viewModel.isHugged,
                showDelete: false,
                onPrimary: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()

                    // Highlight the newly created moment
                    highlightService.highlightMoment(viewModel.clientId)

                    selectedTab = 1 // Navigate to Moments tab
                    onDismiss()

                    // Note: We don't cancel polling here - let it continue in background
                    // to update the moment with AI praise when ready
                },
                onHug: {
                    Task { await viewModel.toggleHug() }
                },
                onDelete: nil,
                isPrimaryDisabled: viewModel.isNiceButtonDisabled
            )
            .iPadContentWidth()
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .opacity(viewModel.showButton ? 1 : 0)
            .offset(y: viewModel.showButton ? 0 : 20)
        }
        .task {
            await viewModel.startEntranceAnimation()
            // Start syncing and fetching AI praise
            await viewModel.syncMomentAndFetchPraise()
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(viewModel.tags.enumerated()), id: \.offset) { index, tag in
                    Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
                        .font(.appCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.appSecondary.opacity(0.6))
                        )
                        .opacity(viewModel.showTags ? 1 : 0)
                        .animation(
                            .easeOut(duration: 0.3).delay(Double(index) * 0.1),
                            value: viewModel.showTags
                        )
                }
            }
        }
    }

}

// MARK: - Preview

#Preview("Praise Content - Static") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        PraiseContentView(
            viewModel: {
                let vm = MockPraiseViewModel(
                    momentText: "I finally cleaned my desk after three weeks",
                    timeAgoSeconds: nil
                )
                vm.showContent = true
                vm.showPraise = true
                vm.showButton = true
                vm.aiPraise = "That's awesome! Taking care of your space is taking care of yourself. A clean desk can really help clear your mind too."
                vm.tags = ["self_care", "productivity", "wins"]
                vm.showTags = true
                return vm
            }(),
            selectedTab: .constant(0)
        ) {
            print("Dismissed")
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Praise Content - Loading") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        PraiseContentView(
            viewModel: {
                let vm = MockPraiseViewModel(
                    momentText: "I called my mom today",
                    timeAgoSeconds: 3600
                )
                vm.showContent = true
                vm.showPraise = true
                vm.showButton = true
                vm.isLoadingAIPraise = true
                return vm
            }(),
            selectedTab: .constant(0)
        ) {
            print("Dismissed")
        }
    }
    .preferredColorScheme(.dark)
}

// MARK: - Mock ViewModel for Previews

@MainActor
@Observable
private final class MockPraiseViewModel: PraiseViewModelProtocol {
    // Moment data
    let momentText: String
    let happenedAt: Date
    let timeAgoSeconds: Int?
    let clientId: UUID
    let submittedAt: Date
    let timezone: String

    // Praise state
    var offlinePraise: String
    var aiPraise: String?
    var tags: [String] = []
    var isLoadingAIPraise: Bool = false
    var syncError: String?

    // Sync failure state
    var isLimitBlocked: Bool = false

    // Animation state
    var showContent: Bool = false
    var showPraise: Bool = false
    var showTags: Bool = false
    var showButton: Bool = false

    var displayedPraise: String {
        aiPraise ?? offlinePraise
    }

    var isShowingAIPraise: Bool {
        aiPraise != nil
    }

    var isNiceButtonDisabled: Bool {
        false  // Mock never disables button
    }

    var isSyncFailed: Bool {
        (isLimitBlocked || syncError != nil) && !isLoadingAIPraise
    }

    // Hug state
    var isHugged: Bool = false

    var timeDisplayText: String {
        guard let seconds = timeAgoSeconds, seconds > 0 else {
            return "Just now"
        }

        if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    init(
        momentText: String,
        happenedAt: Date = Date(),
        timeAgoSeconds: Int? = nil,
        offlinePraise: String? = nil,
        clientId: UUID = UUID(),
        submittedAt: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) {
        self.momentText = momentText
        self.happenedAt = happenedAt
        self.timeAgoSeconds = timeAgoSeconds
        self.offlinePraise = offlinePraise ?? "That's it. Small stuff adds up."
        self.clientId = clientId
        self.submittedAt = submittedAt
        self.timezone = timezone
    }

    func cancelPolling() {
        // No-op for mock
    }

    func startEntranceAnimation() async {
        // No-op for mock - state is set manually
    }

    func syncMomentAndFetchPraise() async {
        // No-op for mock - state is set manually
    }

    func retrySyncMoment() async {
        // No-op for mock - state is set manually
    }

    func toggleHug() async {
        isHugged.toggle()
    }
}
