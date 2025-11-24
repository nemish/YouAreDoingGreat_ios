import SwiftUI

// MARK: - Praise Content View
// Inline praise content to be used within LogMomentView
// Dark mode only for v1

struct PraiseContentView: View {
    @Bindable var viewModel: PraiseViewModel
    var onDismiss: () -> Void

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

                // Praise message
                Text(viewModel.displayedPraise)
                    .font(.appHeadline)
                    .foregroundStyle(.textHighlightOnePrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .opacity(viewModel.showPraise ? 1 : 0)
                    .offset(y: viewModel.showPraise ? 0 : 10)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Done button
            PrimaryButton(title: "Nice") {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                onDismiss()
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
            .opacity(viewModel.showButton ? 1 : 0)
            .offset(y: viewModel.showButton ? 0 : 20)
        }
        .task {
            await viewModel.startEntranceAnimation()
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
