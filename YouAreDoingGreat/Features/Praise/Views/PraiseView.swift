import SwiftUI

// MARK: - Praise Content View
// Inline praise content to be used within LogMomentView
// Dark mode only for v1

struct PraiseContentView: View {
    @Bindable var viewModel: PraiseViewModel
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
                celebrationIcon
                    .opacity(viewModel.showContent ? 1 : 0)
                    .scaleEffect(viewModel.showContent ? 1 : 0.5)

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
                        HStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .textTertiary))
                                .scaleEffect(0.8)
                            Text("Generating praise...")
                                .font(.appCaption)
                                .foregroundStyle(.textTertiary)
                        }
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
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
                        .transition(.opacity.combined(with: .move(edge: .top)))
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

                // Tags section
                if !viewModel.tags.isEmpty {
                    tagsSection
                        .opacity(viewModel.showTags ? 1 : 0)
                        .offset(y: viewModel.showTags ? 0 : 10)
                }
            }
            .padding(.horizontal, 32)
            .animation(.easeInOut(duration: 0.3), value: viewModel.isLoadingAIPraise)

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
}

// MARK: - Preview

#Preview("Praise Content") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        PraiseContentView(
            viewModel: {
                let vm = PraiseViewModel(
                    momentText: "I finally cleaned my desk after three weeks",
                    timeAgoSeconds: nil
                )
                vm.showContent = true
                vm.showPraise = true
                vm.showButton = true
                return vm
            }()
        ) {
            print("Dismissed")
        }
    }
    .preferredColorScheme(.dark)
}
