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

    func cancelPolling()
    func startEntranceAnimation() async
    func syncMomentAndFetchPraise() async
}

// MARK: - Praise Content View
// Inline praise content to be used within LogMomentView
// Dark mode only for v1

struct PraiseContentView<ViewModel: PraiseViewModelProtocol>: View {
    @Bindable var viewModel: ViewModel
    var onDismiss: () -> Void

    // Paywall state
    @State private var paywallService = PaywallService.shared
    @State private var showPaywall = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Main content area
            VStack(spacing: 32) {
                // Celebration icon
//                celebrationIcon
//                    .opacity(viewModel.showContent ? 1 : 0)
//                    .scaleEffect(viewModel.showContent ? 1 : 0.5)

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
                        wordDelay: 0.08
                    )

                    // Loading indicator for AI praise
                    if viewModel.isLoadingAIPraise {
                        MomentSyncLoadingView()
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.8)),
                                removal: .opacity.combined(with: .scale(scale: 0.8))
                            ))
                    }

                    // AI praise text (shown below offline praise when available) with word-by-word animation
                    if let aiPraise = viewModel.aiPraise, !aiPraise.isEmpty {
                        AnimatedTextView(
                            text: aiPraise,
                            font: .appBody,
                            foregroundStyle: Color.textSecondary,
                            multilineTextAlignment: .center,
                            wordDelay: 0.08
                        )
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.9).combined(with: .move(edge: .top))),
                            removal: .opacity.combined(with: .scale(scale: 0.9))
                        ))
                    }

                    // Error message
                    if let error = viewModel.syncError, !viewModel.isLoadingAIPraise {
                        Text(error)
                            .font(.appCaption)
                            .foregroundStyle(.textTertiary)
                            .multilineTextAlignment(.center)
                            .transition(.opacity)
                    }
                }
                .opacity(viewModel.showPraise ? 1 : 0)
                .offset(y: viewModel.showPraise ? 0 : 10)
                .animation(.easeInOut(duration: 0.5), value: viewModel.isLoadingAIPraise)
                .animation(.easeInOut(duration: 0.5), value: viewModel.aiPraise)

                // Tags section
                if !viewModel.tags.isEmpty {
                    tagsSection
                        .opacity(viewModel.showTags ? 1 : 0)
                        .offset(y: viewModel.showTags ? 0 : 10)
                }
            }
            .padding(.horizontal, 32)

            Spacer()

            // Done button
            PrimaryButton(title: "Nice") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.cancelPolling()
                onDismiss()
            }
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
        .onChange(of: paywallService.shouldShowPaywall) { _, shouldShow in
            showPaywall = shouldShow
        }
        .fullScreenCover(isPresented: $showPaywall, onDismiss: {
            // Always clear the service flag when paywall is dismissed
            // This handles both programmatic dismissal and interactive gestures
            paywallService.dismissPaywall()

            // Navigate back to home view
            viewModel.cancelPolling()
            onDismiss()
        }) {
            PaywallView {
                // This closure only runs for programmatic dismissal (button taps)
                showPaywall = false
            }
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

    // MARK: - Celebration Icon

//    private var celebrationIcon: some View {
//        ZStack {
//            // Outer glow
//            Circle()
//                .fill(Color.appPrimary.opacity(0.2))
//                .frame(width: 80, height: 80)
//                .blur(radius: 20)
//
//            // Main circle
//            Circle()
//                .fill(
//                    LinearGradient(
//                        colors: [
//                            Color.appPrimary,
//                            Color.appPrimary.opacity(0.8)
//                        ],
//                        startPoint: .topLeading,
//                        endPoint: .bottomTrailing
//                    )
//                )
//                .frame(width: 64, height: 64)
//
//            // Star icon - celebratory, not task-completion
//            Image(systemName: "sparkles")
//                .font(.system(size: 26, weight: .bold))
//                .foregroundStyle(.white)
//        }
//    }
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
            }()
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
            }()
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
}
