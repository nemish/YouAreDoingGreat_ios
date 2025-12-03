import SwiftUI

// MARK: - Home View
// Dark mode only for v1

struct HomeView: View {
    @Binding var selectedTab: Int
    @AppStorage("hasCompletedFirstLog") private var hasCompletedFirstLog = false

    // Breathing animation state
    @State private var breathingScale: CGFloat = 1.0
    @State private var breathingOpacity: Double = 1.0

    // Navigation state
    @State private var showLogMoment = false

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

    // Haptic feedback for phrase tap
    private let lightFeedback = UIImpactFeedbackGenerator(style: .light)

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

                    // Primary action button
                    VStack(spacing: 16) {
                        PrimaryButton(title: "I Did a Thing") {
                            showLogMoment = true
                        }

                        // First-launch hint
                        if !hasCompletedFirstLog {
                            firstLogHint
                        }
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            .starfieldBackground(isPaused: showLogMoment)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                selectRandomPhrase()
                startBreathingAnimation()
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

    // MARK: - Private Methods

    private func selectRandomPhrase() {
        currentPhraseIndex = Int.random(in: 0..<titlePhrases.count)
        currentPhrase = titlePhrases[currentPhraseIndex]
    }

    private func cycleToNextPhrase() {
        lightFeedback.impactOccurred()

        withAnimation(.easeInOut(duration: 0.3)) {
            currentPhraseIndex = (currentPhraseIndex + 1) % titlePhrases.count
            currentPhrase = titlePhrases[currentPhraseIndex]
        }
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
