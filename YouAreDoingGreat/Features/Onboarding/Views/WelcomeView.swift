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

    var onGetStarted: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                // Intro text
                introText

                // Hero title with breathing animation
                heroTitle

                // Sub-headline
                subHeadline

                // Feature bullets
                featureBullets

                // Reassurance block
                reassuranceBlock

                Spacer()
                    .frame(height: 40)

                // CTA Button
                ctaButton

                // Footer with legal links
                footerSection
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .starfieldBackground()
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Intro Text

    private var introText: some View {
        Text("Hey. Glad you're here.")
            .font(.system(.body, design: .rounded))
            .foregroundStyle(Color.appTextSecondary)
            .opacity(showIntro ? 1 : 0)
            .padding(.bottom, 16)
    }

    // MARK: - Hero Title

    private var heroTitle: some View {
        Text("You're doing better\nthan you think.")
            .font(.system(size: 40, weight: .bold, design: .rounded))
            .foregroundStyle(Color.appTextPrimary)
            .multilineTextAlignment(.center)
            .scaleEffect(breathingScale)
            .opacity(showTitle ? breathingOpacity : 0)
            .padding(.bottom, 24)
    }

    // MARK: - Sub-Headline

    private var subHeadline: some View {
        VStack(spacing: 8) {
            Text("This app helps you notice the small wins you usually ignore…")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)

            Text("and then feel a bit better about being a human disaster.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .opacity(showSubHeadline ? 1 : 0)
        .padding(.horizontal, 8)
        .padding(.bottom, 32)
    }

    // MARK: - Feature Bullets

    private var featureBullets: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureBullet("Log something you did.")
            featureBullet("Get a little praise.")
            featureBullet("Watch yourself slowly become less miserable.")
        }
        .opacity(showFeatures ? 1 : 0)
        .padding(.bottom, 32)
    }

    private func featureBullet(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.primary)

            Text(text)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    // MARK: - Reassurance Block

    private var reassuranceBlock: some View {
        Text("Don't worry, no toxic positivity. Just tiny steps and a little honesty.")
            .font(.system(.callout, design: .rounded))
            .foregroundStyle(Color.appTextSecondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        PrimaryButton(title: "Alright, let's do this") {
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
                    .foregroundStyle(Color.appTextTertiary)
            }

            Text("•")
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(Color.appTextTertiary)

            Button {
                openTerms()
            } label: {
                Text("Terms")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Color.appTextTertiary)
            }
        }
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
