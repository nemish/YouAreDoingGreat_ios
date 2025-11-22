import SwiftUI

// MARK: - Welcome View
// Dark mode only for v1

struct WelcomeView: View {
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    // Sequential fade-in states
    @State private var showIntro = false
    @State private var showTitle = false
    @State private var showSubHeadline = false
    @State private var showFeatures = false
    @State private var showButton = false
    @State private var showFooter = false

    var onGetStarted: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(height: 100)

            introText

            heroTitle

            subHeadline

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
            startAnimations()
        }
    }

    // MARK: - Intro Text

    private var introText: some View {
        Text("Hey. Glad you're here.")
            .font(.appBody)
            .foregroundStyle(Color.textSecondary)
            .opacity(showIntro ? 1 : 0)
            .padding(.bottom, 16)
    }

    // MARK: - Hero Title

    private var heroTitle: some View {
        Text("You're doing better\nthan you think")
            .font(.appTitle)
            .foregroundStyle(Color.textHighlightOnePrimary)
            .multilineTextAlignment(.center)
            .scaleEffect(breathingScale)
            .opacity(showTitle ? breathingOpacity : 0)
            .padding(.bottom, 24)
    }

    // MARK: - Sub-Headline

    private var subHeadline: some View {
        VStack(spacing: 8) {
            Text("I help you notice the small wins you usually ignore…")
                .font(.appBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Text("and feel a bit better")
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .multilineTextAlignment(.center)
        }
        .opacity(showSubHeadline ? 1 : 0)
        .padding(.horizontal, 8)
        .padding(.bottom, 32)
    }


    // MARK: - CTA Button
    private var ctaButton: some View {
        PrimaryButton(title: "Alright, let's do this", showGlow: true) {
            onGetStarted()
        }
        .opacity(showButton ? 1 : 0)
        .padding(.bottom, 32)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack(spacing: 8) {
            Button {
                openPrivacyPolicy()
            } label: {
                Text("Privacy Policy")
                    .font(.appFootnote)
                    .foregroundStyle(Color.textTertiary)
            }

            Text("•")
                .font(.appFootnote)
                .foregroundStyle(Color.textTertiary)

            Button {
                openTerms()
            } label: {
                Text("Terms")
                    .font(.appFootnote)
                    .foregroundStyle(Color.textTertiary)
            }
        }
        .opacity(showFooter ? 1 : 0)
    }

    // MARK: - Private Methods

    private func startAnimations() {
        // Sequential fade-in animations
        withAnimation(.easeIn(duration: 0.6).delay(0.3)) {
            showIntro = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(0.8)) {
            showTitle = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(1.3)) {
            showSubHeadline = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(1.8)) {
            showFeatures = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(2.3)) {
            showButton = true
        }

        withAnimation(.easeIn(duration: 0.6).delay(2.8)) {
            showFooter = true
        }

        // Breathing animation for title
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
            .delay(0.8)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.85
        }
    }

    private func openPrivacyPolicy() {
        // TODO: Open privacy policy URL in SafariView
        if let url = URL(string: "https://example.com/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }

    private func openTerms() {
        // TODO: Open terms URL in SafariView
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
