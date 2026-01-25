import SwiftUI
import SwiftData

// MARK: - Home View
// Dark mode only for v1

struct HomeView: View {
    @Binding var selectedTab: Int
    @AppStorage("hasCompletedFirstLog") private var hasCompletedFirstLog = false
    var animatePremiumBadge: Bool = false

    // SwiftData query for moments (sorted newest first)
    @Query(sort: \Moment.submittedAt, order: .reverse) private var moments: [Moment]

    // Timer since last moment
    @State private var timerTimeValue: String?  // e.g. "9 minutes" or "Nice. Logged."
    @State private var timerPhrase: String?
    @State private var currentTimeBucket: TimeBucket?
    private let timerPhrases = TimerPhrases.load()

    private enum TimeBucket {
        case zeroToTen
        case tenToThirty
        case thirtyToTwoHours
        case twoHoursPlus

        static func from(minutes: Int) -> TimeBucket {
            switch minutes {
            case 0..<10: return .zeroToTen
            case 10..<30: return .tenToThirty
            case 30..<120: return .thirtyToTwoHours
            default: return .twoHoursPlus
            }
        }
    }

    // Premium status
    private var isPremium: Bool {
        SubscriptionService.shared.hasActiveSubscription
    }

    // Premium badge animation
    @State private var premiumBadgeGlow: CGFloat = 0
    @State private var shouldAnimatePremiumBadge = false

    // Breathing animation state
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    // Navigation state
    @State private var showLogMoment = false

    // Premium thank-you card
    @State private var showPremiumThankYou = false

    // Title phrases - tap to cycle
    private let titlePhrases = [
        "Most of life is just doing stuff you don't want to do, a little earlier than you were ready.",
        "You don't need to fix everything. Just... clean one dish. Then see what happens.",
        "You're not lazy. You're just overwhelmed and have wifi.",
        "Some days you win. Some days you brush your teeth and that's it.",
        "The hardest thing in the world is starting. And you're alive, so technically, you started.",
        "The bar for success is lower than you think. It's basically on the floor.",
        "You don't need to be amazing. You need to be slightly less catastrophic than yesterday.",
        "Life is just a series of \"ugh, fine\" moments strung together.",
        "Doing something badly still counts as doing it.",
        "You're not supposed to feel motivated. That's a lie invented by fitness instructors.",
        "Everyone else is also struggling. They're just better at filters.",
        "You can move through a day without yelling at yourself. Try it. It's weird.",
        "Someone out there thinks you're doing great. They're wrong. But it's nice.",
        "Most things you're worried about don't matter. The rest will happen anyway.",
        "You don't have to win. Just... don't lose to the couch again.",
        "Your brain is a jerk. Don't let it be in charge.",
        "Action beats thinking. Almost every time.",
        "Everyone's faking it. Some people are just wearing pants.",
        "The first step is usually something dumb. Take it anyway.",
        "If you showed up, you're already halfway to something. Even if it's a nap."
    ]

    @State private var currentPhrase: String = ""
    @State private var currentPhraseIndex: Int = 0

    var body: some View {
        NavigationStack {
            ZStack {
                // Content
                VStack(spacing: 0) {
                    Spacer()

                    // Title phrase - tap to cycle
                    Text(currentPhrase)
                        .font(.appTitle3)
                        .foregroundStyle(.textHighlightOnePrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .scaleEffect(breathingScale)
                        .opacity(breathingOpacity)
                        .onTapGesture {
                            cycleToNextPhrase()
                        }

                    Spacer()

                    // Primary action button and thank-you card
                    VStack(spacing: 16) {
                        // Premium thank-you card (shown after successful subscription)
                        if showPremiumThankYou {
                            PremiumThankYouCard {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    showPremiumThankYou = false
                                }
                            }
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .bottom))
                            ))
                        }

                        // Timer since last moment
                        if let timerTimeValue, let timerPhrase {
                            LastMomentTimerView(timeValue: timerTimeValue, phrase: timerPhrase)
                        }

                        PrimaryButton(title: "I Did a Thing") {
                            showLogMoment = true
                        }

                        // First-launch hint
                        if !hasCompletedFirstLog {
                            firstLogHint
                        }
                    }
                    .iPadContentWidth()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .starfieldBackground(isPaused: showLogMoment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                premiumBadge
                    .padding(.top, 8)
                    .padding(.trailing, 16)
            }
            .onAppear {
                selectRandomPhrase()
                startBreathingAnimation()
                loadTimerData()
            }
            .onChange(of: animatePremiumBadge) { _, newValue in
                if newValue && isPremium {
                    startPremiumBadgePulse()
                    // Show thank-you card after successful subscription
                    withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                        showPremiumThankYou = true
                    }
                }
            }
            .onChange(of: showLogMoment) { _, isShowing in
                // Refresh timer when returning from LogMomentView
                if !isShowing {
                    loadTimerData()
                }
            }
        }
        .sheet(isPresented: $showLogMoment) {
            LogMomentView(isFirstLog: !hasCompletedFirstLog, selectedTab: $selectedTab) {
                // On save callback
                if !hasCompletedFirstLog {
                    hasCompletedFirstLog = true
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
        }
    }
    
    private var firstLogHint: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 8) {
                Spacer(minLength: 0)
                
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "arrow.turn.left.up")
                        .font(.system(size: 16))
                        .foregroundStyle(.textPrimary)
                    
                    Text("Hey… installing the app counts too. Let's log that tiny win?")
                        .font(.appFootnoteWriting)
                        .foregroundStyle(.textPrimary)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: geometry.size.width * 0.7, alignment: .trailing)
            }
        }
        .frame(height: 60)
        .padding(.top, 8)
    }

    @ViewBuilder
    private var premiumBadge: some View {
        if isPremium {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                Text("Premium")
                    .font(.appFootnote)
            }
            .foregroundStyle(.textPrimary.opacity(0.4 + (premiumBadgeGlow * 0.6)))
            .scaleEffect(1 + (premiumBadgeGlow * 0.1))
            .onAppear {
                if shouldAnimatePremiumBadge {
                    startPremiumBadgePulse()
                    shouldAnimatePremiumBadge = false
                }
            }
        }
    }

    private func startPremiumBadgePulse() {
        Task { @MainActor in
            // Cycle 1: In
            withAnimation(.easeInOut(duration: 0.5)) {
                premiumBadgeGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 1: Out
            withAnimation(.easeInOut(duration: 0.5)) {
                premiumBadgeGlow = 0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 2: In
            withAnimation(.easeInOut(duration: 0.5)) {
                premiumBadgeGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            // Cycle 2: Out
            withAnimation(.easeOut(duration: 0.5)) {
                premiumBadgeGlow = 0
            }
        }
    }

    // MARK: - Private Methods

    private func loadTimerData() {
        guard let lastMoment = moments.first else {
            timerTimeValue = nil
            timerPhrase = nil
            currentTimeBucket = nil
            return
        }

        let interval = Date().timeIntervalSince(lastMoment.submittedAt)
        let totalMinutes = Int(interval / 60)

        timerTimeValue = LastMomentTimerView.formatTimeValue(totalMinutes: totalMinutes)

        // Only update phrase when bucket changes
        let newBucket = TimeBucket.from(minutes: totalMinutes)
        if currentTimeBucket != newBucket {
            currentTimeBucket = newBucket
            timerPhrase = timerPhrases?.randomPhrase(forMinutesSinceLast: totalMinutes)
        }
    }

    private func selectRandomPhrase() {
        currentPhraseIndex = Int.random(in: 0..<titlePhrases.count)
        currentPhrase = titlePhrases[currentPhraseIndex]
    }

    private func cycleToNextPhrase() {
        Task { await HapticManager.shared.play(.gentleTap) }

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhraseIndex = (currentPhraseIndex + 1) % titlePhrases.count
            currentPhrase = titlePhrases[currentPhraseIndex]
        }
    }

    private func startBreathingAnimation() {
        // Delay to allow transition from Welcome view to complete (0.5s)
        // This prevents animation phase mismatch between the two breathing animations
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
            .delay(0.6)
        ) {
            breathingScale = 1.05
            breathingOpacity = 0.85
        }
    }
}

// MARK: - Preview

#Preview("Home View") {
    HomeView(selectedTab: .constant(0))
        .preferredColorScheme(.dark)
}

#Preview("Home View - First Launch") {
    HomeView(selectedTab: .constant(0))
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedFirstLog")
        }
        .preferredColorScheme(.dark)
}

#Preview("Home View - Premium Badge") {
    PremiumBadgePreview()
        .preferredColorScheme(.dark)
}

// MARK: - Premium Badge Preview Helper

private struct PremiumBadgePreview: View {
    @State private var badgeGlow: CGFloat = 0
    @State private var animateBadge = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    Spacer()

                    Text("You're not lazy. You're just overwhelmed and have wifi.")
                        .font(.appTitle3)
                        .foregroundStyle(.textHighlightOnePrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Spacer()

                    VStack(spacing: 16) {
                        PrimaryButton(title: "I Did a Thing") {}
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .starfieldBackground(isPaused: false)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                HStack(alignment: .center, spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                    Text("Premium")
                        .font(.appFootnote)
                }
                .foregroundStyle(.textPrimary.opacity(0.4 + (badgeGlow * 0.6)))
                .scaleEffect(1 + (badgeGlow * 0.1))
                .padding(.top, 8)
                .padding(.trailing, 16)
            }
        }
        .onAppear {
            startPulse()
        }
    }

    private func startPulse() {
        Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.5)) {
                badgeGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            withAnimation(.easeInOut(duration: 0.5)) {
                badgeGlow = 0
            }
            try? await Task.sleep(for: .seconds(0.5))

            withAnimation(.easeInOut(duration: 0.5)) {
                badgeGlow = 1.0
            }
            try? await Task.sleep(for: .seconds(0.5))

            withAnimation(.easeOut(duration: 0.5)) {
                badgeGlow = 0
            }
        }
    }
}
