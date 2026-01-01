import SwiftUI

// MARK: - Breathing Shimmer Modifier
// Adds a gentle breathing effect (scale + opacity) combined with
// a white/silver shimmer sweep that runs continuously after a delay.
// Designed for praise text to add polish without distraction.

struct BreathingShimmerModifier: ViewModifier {
    let initialDelay: TimeInterval
    let breathingDuration: TimeInterval
    let shimmerDuration: TimeInterval

    @State private var isAnimating = false
    @State private var shimmerOffset: CGFloat = -1.0

    init(
        initialDelay: TimeInterval = 5.0,
        breathingDuration: TimeInterval = 3.0,
        shimmerDuration: TimeInterval = 2.0
    ) {
        self.initialDelay = initialDelay
        self.breathingDuration = breathingDuration
        self.shimmerDuration = shimmerDuration
    }

    func body(content: Content) -> some View {
        content
            // Breathing: scale effect
            .scaleEffect(isAnimating ? 1.015 : 1.0)
            // Breathing: opacity effect
            .opacity(isAnimating ? 0.85 : 1.0)
            // Animate breathing with autoreverse
            .animation(
                isAnimating
                    ? .easeInOut(duration: breathingDuration / 2).repeatForever(autoreverses: true)
                    : .default,
                value: isAnimating
            )
            // Shimmer overlay
            .overlay {
                GeometryReader { geometry in
                    shimmerGradient
                        .frame(width: geometry.size.width * 0.4) // Shimmer width is 40% of text
                        .offset(x: shimmerOffset * (geometry.size.width * 1.4))
                        .mask(content) // Mask to text shape
                }
                .allowsHitTesting(false)
            }
            .task {
                await startAnimations()
            }
    }

    private var shimmerGradient: some View {
        LinearGradient(
            colors: [
                .clear,
                .white.opacity(0.0),
                .white.opacity(0.35),
                .white.opacity(0.0),
                .clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .blendMode(.overlay)
    }

    private func startAnimations() async {
        // Wait for word-by-word animation to complete + initial delay
        try? await Task.sleep(nanoseconds: UInt64(initialDelay * 1_000_000_000))

        // Start breathing
        withAnimation {
            isAnimating = true
        }

        // Start shimmer loop
        await runShimmerLoop()
    }

    private func runShimmerLoop() async {
        while !Task.isCancelled {
            // Reset to start position
            shimmerOffset = -1.0

            // Animate shimmer sweep
            withAnimation(.easeInOut(duration: shimmerDuration)) {
                shimmerOffset = 1.0
            }

            // Wait for animation to complete + pause before next sweep
            try? await Task.sleep(nanoseconds: UInt64((shimmerDuration + breathingDuration) * 1_000_000_000))
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds a breathing effect (scale + opacity pulse) with a shimmer sweep.
    /// - Parameters:
    ///   - initialDelay: Delay before animations start (default: 5 seconds)
    ///   - breathingDuration: Full cycle duration for breathing (default: 3 seconds)
    ///   - shimmerDuration: Duration of shimmer sweep (default: 2 seconds)
    func breathingShimmer(
        initialDelay: TimeInterval = 5.0,
        breathingDuration: TimeInterval = 3.0,
        shimmerDuration: TimeInterval = 2.0
    ) -> some View {
        modifier(BreathingShimmerModifier(
            initialDelay: initialDelay,
            breathingDuration: breathingDuration,
            shimmerDuration: shimmerDuration
        ))
    }
}

// MARK: - Preview

#Preview("Breathing Shimmer - AI Praise") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 40) {
            Text("Without Effect")
                .font(.appCaption)
                .foregroundStyle(.gray)

            Text("That's awesome! Taking care of your space is taking care of yourself.")
                .font(.appBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)

            Divider()
                .background(.gray.opacity(0.3))
                .padding(.horizontal, 40)

            Text("With Breathing Shimmer (starts after 2s for preview)")
                .font(.appCaption)
                .foregroundStyle(.gray)

            Text("That's awesome! Taking care of your space is taking care of yourself.")
                .font(.appBody)
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .breathingShimmer(initialDelay: 2.0) // Shorter delay for preview
        }
        .padding(.horizontal, 32)
    }
    .preferredColorScheme(.dark)
}

#Preview("Breathing Shimmer - Immediate") {
    ZStack {
        Color.black.ignoresSafeArea()

        Text("Every little bit matters. You're making real progress here.")
            .font(.appHeadline)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .breathingShimmer(initialDelay: 0.5)
    }
    .preferredColorScheme(.dark)
}
