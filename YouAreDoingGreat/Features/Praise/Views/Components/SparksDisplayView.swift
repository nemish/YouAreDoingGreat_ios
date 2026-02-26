import SwiftUI

// MARK: - Sparks Display View
// Shows sparks earned for a moment with long-press to collect

struct SparksDisplayView: View {
    let sparksAwarded: Int
    let onCollect: () -> Void

    @State private var isRevealed = false
    @State private var collectProgress: CGFloat = 0
    @State private var isPressing = false
    @State private var particlePhase: CGFloat = 0
    @State private var glowOpacity: Double = 0.3

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 12) {
            // Sparks count with glow and progress ring
            ZStack {
                // Glow background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.appPrimary.opacity(glowOpacity),
                                Color.appPrimary.opacity(0)
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)

                // Progress ring (visible during long-press)
                Circle()
                    .trim(from: 0, to: collectProgress)
                    .stroke(
                        Color.appPrimary,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Sparks count
                VStack(spacing: 2) {
                    Text("+\(sparksAwarded)")
                        .font(.comfortaa(28, weight: .bold))
                        .foregroundStyle(Color.appPrimary)

                    Text("sparks")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            // Instruction hint
            Text("hold to collect")
                .font(.appFootnote)
                .foregroundStyle(.textTertiary)
                .opacity(isPressing ? 0 : 0.7)
                .padding(.bottom, 16)
        }
        .scaleEffect(isRevealed ? 1 : 0.8)
        .opacity(isRevealed ? 1 : 0)
        .onAppear {
            if !reduceMotion {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7).delay(0.2)) {
                    isRevealed = true
                }
                // Breathing glow
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    glowOpacity = 0.5
                }
            } else {
                isRevealed = true
            }
        }
        .onLongPressGesture(minimumDuration: 1.0) {
            // Collection completed
            onCollect()
        } onPressingChanged: { pressing in
            isPressing = pressing
            if pressing {
                withAnimation(.linear(duration: 1.0)) {
                    collectProgress = 1.0
                }
            } else {
                // Cancelled - rewind ring
                withAnimation(.easeOut(duration: 0.2)) {
                    collectProgress = 0
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("+\(sparksAwarded) sparks earned")
        .accessibilityHint("Long press to collect sparks")
    }
}

// MARK: - Preview

#Preview("Sparks Display") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        SparksDisplayView(sparksAwarded: 73) {
            print("Collected!")
        }
    }
    .preferredColorScheme(.dark)
}
