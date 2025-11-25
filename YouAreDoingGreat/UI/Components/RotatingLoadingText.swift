import SwiftUI

// MARK: - Rotating Loading Text
// Displays random encouraging phrases that change every few seconds
// Inspired by the old app's useLoadingText hook

struct RotatingLoadingText: View {
    @State private var currentPhraseIndex = 0
    @State private var timer: Timer?

    // Loading phrases inspired by the old app
    private let loadingPhrases = [
        "Loading...",
        "Thinking...",
        "One sec...",
        "Almost...",
        "Still here...",
        "Finding it...",
        "Just a moment...",
        "Hold tight...",
        "Looking closer...",
        "Warming words...",
        "Lining it up...",
        "Tiny spark...",
        "Softly now...",
        "Turning pages...",
        "Gathering light...",
        "On it...",
        "Tuning in...",
        "Quiet magic...",
        "Almost ready...",
        "Hang on..."
    ]

    var body: some View {
        ZStack {
            ForEach(0..<loadingPhrases.count, id: \.self) { index in
                if index == currentPhraseIndex {
                    Text(loadingPhrases[index])
                        .font(.appBody)
                        .foregroundStyle(.textTertiary)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.92)),
                            removal: .opacity.combined(with: .scale(scale: 1.08))
                        ))
                }
            }
        }
        .onAppear {
            startRotation()
        }
        .onDisappear {
            stopRotation()
        }
    }

    // MARK: - Text Rotation

    private func startRotation() {
        // Start text rotation timer (changes every 3 seconds)
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 1.6)) {
                currentPhraseIndex = Int.random(in: 0..<loadingPhrases.count)
            }
        }
    }

    private func stopRotation() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Preview

#Preview("Rotating Loading Text") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        RotatingLoadingText()
    }
    .preferredColorScheme(.dark)
}
