import SwiftUI

// MARK: - Premium Thank You Card
// Compact card shown on HomeView after successful subscription
// Dark mode only for v1

struct PremiumThankYouCard: View {
    let onDismiss: () -> Void

    // Animation states
    @State private var showHeader = false
    @State private var showSubtitles = false
    @State private var showDivider = false
    @State private var showBenefitsHeader = false
    @State private var showBenefit1 = false
    @State private var showBenefit2 = false
    @State private var showBenefit3 = false
    @State private var showBottomDivider = false
    @State private var showDismissButton = false
    @State private var iconGlow: CGFloat = 0

    // Benefits list
    private let benefits = [
        "up to 10 moments a day",
        "unlimited total moments",
        "full journey history"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with sparkles
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.background.opacity(0.9 + iconGlow * 0.1))
                    .scaleEffect(1 + iconGlow * 0.1)

                Text("Thanks — that really means a lot")
                    .font(.appHeadline)
                    .foregroundStyle(Color.background)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)
            }
            .opacity(showHeader ? 1 : 0)
            .offset(y: showHeader ? 0 : 8)

            // Subtitles
            VStack(alignment: .leading, spacing: 4) {
                Text("You just unlocked the good stuff. Let's keep catching your tiny wins together.")
                    .font(.appFootnote)
                    .foregroundStyle(Color.background.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 32) // Align with text after sparkles icon
            .opacity(showSubtitles ? 1 : 0)
            .offset(y: showSubtitles ? 0 : 8)

            // Dotted divider
            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill(Color.background.opacity(0.25))
                        .frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .opacity(showDivider ? 1 : 0)

            // Benefits section
            VStack(alignment: .leading, spacing: 8) {
                Text("You now get:")
                    .font(.appHeadline)
                    .foregroundStyle(Color.background)
                    .padding(.top, 4)
                    .opacity(showBenefitsHeader ? 1 : 0)
                    .offset(y: showBenefitsHeader ? 0 : 8)

                // Benefit 1
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.background.opacity(0.8))

                    Text(benefits[0])
                        .font(.appFootnote)
                        .foregroundStyle(Color.background.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(showBenefit1 ? 1 : 0)
                .offset(y: showBenefit1 ? 0 : 8)

                // Benefit 2
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.background.opacity(0.8))

                    Text(benefits[1])
                        .font(.appFootnote)
                        .foregroundStyle(Color.background.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(showBenefit2 ? 1 : 0)
                .offset(y: showBenefit2 ? 0 : 8)

                // Benefit 3
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.background.opacity(0.8))

                    Text(benefits[2])
                        .font(.appFootnote)
                        .foregroundStyle(Color.background.opacity(0.55))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .opacity(showBenefit3 ? 1 : 0)
                .offset(y: showBenefit3 ? 0 : 8)
            }
            .padding(.leading, 32) // Align with text after sparkles icon

            // Bottom dotted divider
            HStack(spacing: 4) {
                ForEach(0..<30, id: \.self) { _ in
                    Circle()
                        .fill(Color.background.opacity(0.25))
                        .frame(width: 3, height: 3)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .opacity(showBottomDivider ? 1 : 0)

            // Dismiss button - right aligned
            HStack {
                Spacer()
                Button {
                    Task { await HapticManager.shared.play(.gentleTap) }
                    onDismiss()
                } label: {
                    Text(NSLocalizedString("premium_thank_you_dismiss", comment: ""))
                        .font(.appHeadline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.appPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.background.opacity(0.8))
                        )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .opacity(showDismissButton ? 1 : 0)
            .offset(y: showDismissButton ? 0 : 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.appPrimary)
                .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            startStaggeredAnimation()
            startIconGlowPulse()
        }
    }

    // MARK: - Staggered Animation

    private func startStaggeredAnimation() {
        Task { @MainActor in
            // Header
            withAnimation(.easeOut(duration: 0.3)) {
                showHeader = true
            }
            try? await Task.sleep(for: .seconds(0.15))

            // Subtitles
            withAnimation(.easeOut(duration: 0.3)) {
                showSubtitles = true
            }
            try? await Task.sleep(for: .seconds(0.15))

            // Divider
            withAnimation(.easeOut(duration: 0.25)) {
                showDivider = true
            }
            try? await Task.sleep(for: .seconds(0.1))

            // Benefits header
            withAnimation(.easeOut(duration: 0.3)) {
                showBenefitsHeader = true
            }
            try? await Task.sleep(for: .seconds(0.1))

            // Benefit 1
            withAnimation(.easeOut(duration: 0.3)) {
                showBenefit1 = true
            }
            try? await Task.sleep(for: .seconds(0.08))

            // Benefit 2
            withAnimation(.easeOut(duration: 0.3)) {
                showBenefit2 = true
            }
            try? await Task.sleep(for: .seconds(0.08))

            // Benefit 3
            withAnimation(.easeOut(duration: 0.3)) {
                showBenefit3 = true
            }
            try? await Task.sleep(for: .seconds(0.1))

            // Bottom divider
            withAnimation(.easeOut(duration: 0.25)) {
                showBottomDivider = true
            }
            try? await Task.sleep(for: .seconds(0.1))

            // Dismiss button
            withAnimation(.easeOut(duration: 0.3)) {
                showDismissButton = true
            }
        }
    }

    // MARK: - Icon Glow Animation

    private func startIconGlowPulse() {
        Task { @MainActor in
            // Cycle 1: In
            withAnimation(.easeInOut(duration: 0.5)) {
                iconGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 1: Out
            withAnimation(.easeInOut(duration: 0.5)) {
                iconGlow = 0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 2: In
            withAnimation(.easeInOut(duration: 0.5)) {
                iconGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 2: Out
            withAnimation(.easeOut(duration: 0.5)) {
                iconGlow = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("Premium Thank You Card") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack {
            Spacer()

            PremiumThankYouCard {
                print("Dismissed")
            }
            .padding(.horizontal, 32)

            Spacer()
                .frame(height: 100)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Premium Thank You Card - In Context") {
    ZStack {
        Color.clear
            .starfieldBackground(isPaused: false)

        VStack {
            Spacer()

            VStack(spacing: 16) {
                PremiumThankYouCard {
                    print("Dismissed")
                }

                // Simulated CTA button
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient.primaryButton)
                    .frame(height: 56)
                    .overlay {
                        Text("I Did a Thing")
                            .font(.appHeadline)
                            .foregroundStyle(.textPrimary)
                    }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
    .preferredColorScheme(.dark)
}
