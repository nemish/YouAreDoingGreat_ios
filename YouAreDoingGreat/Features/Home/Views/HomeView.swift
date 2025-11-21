import SwiftUI

// MARK: - Home View
// Dark mode only for v1

struct HomeView: View {
    @AppStorage("hasCompletedFirstLog") private var hasCompletedFirstLog = false

    // Breathing animation state
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    // Navigation state
    @State private var showLogMoment = false
    @State private var showSettings = false

    // Random supportive phrases
    private let supportivePhrases = [
        "You Are Doing Great",
        "You're doing better than you think",
        "Small steps still count",
        "Progress, not perfection",
        "You showed up today",
        "That's already something"
    ]

    @State private var currentPhrase: String = ""

    var body: some View {
        ZStack {
            // Content
            VStack(spacing: 0) {
                // Settings button
                HStack {
                    Spacer()
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                Spacer()

                // Center content
                VStack(spacing: 32) {
                    // Breathing supportive phrase
                    Text(currentPhrase)
                        .font(.appTitle)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.center)
                        .scaleEffect(breathingScale)
                        .opacity(breathingOpacity)

                    // Primary action button
                    VStack(spacing: 16) {
                        PrimaryButton(title: "I Did a Thing") {
                            showLogMoment = true
                        }

                        // First-launch hint
                        if !hasCompletedFirstLog {
                            Text("Hey… installing the app counts too. Wanna log that tiny win?")
                                .font(.appFootnoteWriting)
                                .foregroundStyle(Color.primary)
                                .multilineTextAlignment(.center)
                                .padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 32)
                }

                Spacer()
            }
        }
        .starfieldBackground()
        .onAppear {
            selectRandomPhrase()
            startBreathingAnimation()
        }
        .sheet(isPresented: $showLogMoment) {
            // TODO: LogMomentView
            Text("Log Moment Screen")
                .presentationDetents([.large])
        }
        .sheet(isPresented: $showSettings) {
            // TODO: SettingsView
            Text("Settings Screen")
                .presentationDetents([.large])
        }
    }

    // MARK: - Private Methods

    private func selectRandomPhrase() {
        currentPhrase = supportivePhrases.randomElement() ?? "You Are Doing Great"
    }

    private func startBreathingAnimation() {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.85
        }
    }
}

// MARK: - Preview

#Preview("Home View") {
    HomeView()
        .preferredColorScheme(.dark)
}

#Preview("Home View - First Launch") {
    HomeView()
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedFirstLog")
        }
        .preferredColorScheme(.dark)
}
