import SwiftUI

// MARK: - Welcome View
// Dark mode only for v1

struct WelcomeView: View {
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    // Sequential fade-in states
    @State private var showIntro = false
    @State private var showTitle = false
    @State private var showSubHeadline1 = false
    @State private var showSubHeadline2 = false
    @State private var showCTA = false

    var onGetStarted: () -> Void

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()

                introText

                subHeadline1

                subHeadline2

                heroTitle
                    .frame(maxWidth: .infinity, alignment: .center)

                Spacer()
                    .frame(height: geometry.size.height * 0.15)

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
        Text("You Are Doing Great")
            .font(.appTitle)
            .foregroundStyle(Color.textHighlightOnePrimary)
            .multilineTextAlignment(.center)
            .scaleEffect(breathingScale)
            .opacity(showTitle ? breathingOpacity : 0)
            .padding(.bottom, 24)
    }

    // MARK: - Sub-Headline 1

    private var subHeadline1: some View {
        Text("I help you notice the small wins you usually ignore…")
            .font(.appBody)
            .foregroundStyle(Color.textSecondary)
            .multilineTextAlignment(.center)
            .opacity(showSubHeadline1 ? 1 : 0)
            .padding(.horizontal, 8)
            .padding(.bottom, 24)
    }

    // MARK: - Sub-Headline 2

    private var subHeadline2: some View {
        Text("because even on weird days")
            .font(.appBody)
            .foregroundStyle(.textPrimary)
            .fontWeight(.bold)
            .multilineTextAlignment(.center)
            .opacity(showSubHeadline2 ? 1 : 0)
            .padding(.horizontal, 8)
            .padding(.bottom, 40)
    }


    // MARK: - CTA Button
    private var ctaButton: some View {
        PrimaryButton(title: "Alright, let's do this", showGlow: true) {
            onGetStarted()
        }
        .iPadContentWidth()
        .opacity(showCTA ? 1 : 0)
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
        .opacity(showCTA ? 1 : 0)
    }

    // MARK: - Private Methods

    private func startAnimations() {
        // Sequential fade-in animations (slower with bigger delays)
        withAnimation(.easeIn(duration: 1.2).delay(1.0)) {
            showIntro = true
        }

        withAnimation(.easeIn(duration: 1.2).delay(3.5)) {
            showSubHeadline1 = true
        }

        withAnimation(.easeIn(duration: 1.2).delay(6.0)) {
            showSubHeadline2 = true
        }

        withAnimation(.easeIn(duration: 1.2).delay(8.5)) {
            showTitle = true
        }

        withAnimation(.easeIn(duration: 1.2).delay(11.0)) {
            showCTA = true
        }

        // Breathing animation for title
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
            .delay(8.5)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.85
        }
    }

    private func openPrivacyPolicy() {
        UIApplication.shared.open(AppConfig.privacyPolicyURL)
    }

    private func openTerms() {
        UIApplication.shared.open(AppConfig.termsOfServiceURL)
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
