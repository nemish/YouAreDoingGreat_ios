import SwiftUI

// MARK: - Welcome View
// Dark mode only for v1

struct WelcomeView: View {
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Title with breathing animation
            titleSection

            Spacer()

            // CTA Button
            ctaButton

            // Footer with legal links
            footerSection
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 40)
        .starfieldBackground()
        .onAppear {
            startBreathingAnimation()
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 16) {
            Text("You Are Doing Great")
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.center)
                .scaleEffect(breathingScale)
                .opacity(breathingOpacity)

            Text("Log your small wins and get instant encouragement.")
                .font(.system(.title3, design: .rounded))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        PrimaryButton(title: "Get started") {
            onGetStarted()
        }
        .padding(.bottom, 32)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: 8) {
            Button {
                openPrivacyPolicy()
            } label: {
                Text("Privacy Policy")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.textTertiary)
            }

            Text("•")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Color.textTertiary)

            Button {
                openTermsOfUse()
            } label: {
                Text("Terms of Use")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.textTertiary)
            }
        }
    }

    // MARK: - Private Methods

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.8
        }
    }

    private func openPrivacyPolicy() {
        // TODO: Open privacy policy URL in SafariView
        if let url = URL(string: "https://example.com/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }

    private func openTermsOfUse() {
        // TODO: Open terms of use URL in SafariView
        if let url = URL(string: "https://example.com/terms") {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Preview

#Preview("Welcome View") {
    WelcomeView {
        print("Get started tapped")
    }
}

#Preview("Welcome View - Dark") {
    WelcomeView {
        print("Get started tapped")
    }
    .preferredColorScheme(.dark)
}
