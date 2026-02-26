import SwiftUI

// MARK: - Chapter Progress Bar
// Reusable progress bar showing sparks progress toward next chapter
// Used in PraiseView (after collection) and HomeView

struct ChapterProgressBar: View {
    let currentSparks: Int
    let chapterThreshold: Int
    let chapterName: String
    let animateFromProgress: Double?
    let isPulsing: Bool

    @State private var displayProgress: Double = 0
    @State private var shimmerOffset: CGFloat = -0.2
    @State private var pulseScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.2
    @State private var hasAnimated = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var targetProgress: Double {
        guard chapterThreshold > 0 else { return 0 }
        return min(1.0, Double(currentSparks) / Double(chapterThreshold))
    }

    var body: some View {
        VStack(spacing: 8) {
            // Progress track
            GeometryReader { geometry in
                let trackWidth = geometry.size.width
                let fillWidth = max(8, trackWidth * displayProgress)

                ZStack(alignment: .leading) {
                    // Track background
                    Capsule()
                        .fill(Color.white.opacity(0.08))

                    // Filled portion
                    filledBar(trackWidth: trackWidth, fillWidth: fillWidth)

                    // Tick marks (9 inner dividers for 10 segments, dotted vertical lines)
                    ForEach(1..<10, id: \.self) { i in
                        let x = trackWidth * CGFloat(i) / 10.0
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: 0))
                            path.addLine(to: CGPoint(x: 0, y: 8))
                        }
                        .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [1.5, 1.5]))
                        .frame(width: 1, height: 8)
                        .position(x: x, y: 4)
                    }
                }
            }
            .frame(height: 8)
            .scaleEffect(pulseScale)

            // Chapter label
            HStack {
                Text(chapterName)
                    .font(.appFootnote)
                    .foregroundStyle(.textSecondary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundStyle(.appPrimary)
                    Text("\(currentSparks)/\(chapterThreshold)")
                        .font(.appFootnote)
                        .foregroundStyle(.textTertiary)
                }
            }
        }
        .onAppear {
            guard !hasAnimated else { return }
            hasAnimated = true

            if let fromProgress = animateFromProgress {
                displayProgress = max(0, fromProgress)
            }

            // Animate fill
            let delay: Double = animateFromProgress != nil ? 0.2 : 0
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(delay)) {
                displayProgress = targetProgress
            }

            if !reduceMotion {
                // Periodic shimmer sweep with edge pulse at the end
                startPeriodicShimmer(delay: delay + 0.3)
            }

            // Pulse animation for home screen
            if isPulsing && !reduceMotion {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(1.0)) {
                    pulseScale = 1.02
                    glowOpacity = 0.5
                }
            }
        }
        .onChange(of: currentSparks) { _, _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                displayProgress = targetProgress
            }
        }
        .onChange(of: chapterThreshold) { _, _ in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
                displayProgress = targetProgress
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(chapterName), \(currentSparks) of \(chapterThreshold) sparks")
        .accessibilityValue("\(Int(targetProgress * 100)) percent")
    }

    // MARK: - Subviews

    private func filledBar(trackWidth: CGFloat, fillWidth: CGFloat) -> some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color.appPrimary,
                        Color.appPrimary.opacity(0.8),
                        Color(red: 0.25, green: 0.3, blue: 0.55)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: fillWidth)
            .shadow(color: Color.appPrimary.opacity(glowOpacity), radius: 8, y: 0)
            .overlay(
                // Shimmer — sweeps left-to-right using fractional position
                GeometryReader { _ in
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: fillWidth * 0.3)
                    .offset(x: fillWidth * shimmerOffset)
                }
                .clipShape(Capsule())
            )
            .clipShape(Capsule())
    }

    // MARK: - Animations

    private func startPeriodicShimmer(delay: Double) {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            while !Task.isCancelled {
                shimmerOffset = -0.4
                withAnimation(.easeInOut(duration: 1.2)) {
                    shimmerOffset = 1.2
                }
                try? await Task.sleep(nanoseconds: 3_500_000_000)
            }
        }
    }
}

// MARK: - Preview

#Preview("Chapter Progress Bar") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 32) {
            ChapterProgressBar(
                currentSparks: 35,
                chapterThreshold: 50,
                chapterName: "First Light",
                animateFromProgress: 0.4,
                isPulsing: false
            )

            ChapterProgressBar(
                currentSparks: 157,
                chapterThreshold: 200,
                chapterName: "Growing Glow",
                animateFromProgress: nil,
                isPulsing: true
            )

            ChapterProgressBar(
                currentSparks: 5,
                chapterThreshold: 50,
                chapterName: "Prologue",
                animateFromProgress: 0,
                isPulsing: false
            )
        }
        .padding(.horizontal, 32)
    }
    .preferredColorScheme(.dark)
}
