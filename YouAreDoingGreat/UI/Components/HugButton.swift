import SwiftUI

// MARK: - Hug Button
// Animated heart button with gentle pulse animation on tap
// Dark mode only for v1

struct HugButton: View {
    let isHugged: Bool
    let action: () -> Void

    // Animation state
    @State private var animationScale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    @State private var animationTask: Task<Void, Never>?

    // Haptic feedback
    private let impactFeedback = UIImpactFeedbackGenerator(style: .light)

    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // Subtle glow layer (only visible during animation)
                Circle()
                    .fill(Color.pink.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .blur(radius: 8)
                    .opacity(glowOpacity)
                    .scaleEffect(animationScale * 1.2)

                // Heart icon
                Image(systemName: isHugged ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(isHugged ? .pink : .textSecondary)
                    .scaleEffect(animationScale)
            }
            .frame(width: 48, height: 48)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(HugButtonStyle())
        .accessibilityLabel(isHugged ? "Remove hug" : "Hug this moment")
        .accessibilityHint(isHugged
            ? "Double tap to remove hug from this moment"
            : "Double tap to give this moment a hug")
    }

    private func handleTap() {
        impactFeedback.impactOccurred()

        // Cancel any in-flight animation
        animationTask?.cancel()

        if !isHugged {
            // Hugging animation: scale up with glow
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0)) {
                animationScale = 1.25
                glowOpacity = 1.0
            }

            // Return to normal after delay
            animationTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 150_000_000) // 0.15s
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    animationScale = 1.0
                    glowOpacity = 0.0
                }
            }
        } else {
            // Unhugging animation: subtle shrink
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                animationScale = 0.85
            }

            // Return to normal after delay
            animationTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
                guard !Task.isCancelled else { return }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    animationScale = 1.0
                }
            }
        }

        action()
    }
}

// MARK: - Hug Button Style
// Subtle press feedback without interfering with main animation

struct HugButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Hug Button States") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                HugButton(isHugged: false) {
                    print("Hug tapped")
                }
                Text("Not hugged")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }

            VStack(spacing: 8) {
                HugButton(isHugged: true) {
                    print("Unhug tapped")
                }
                Text("Hugged")
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
    .padding(40)
    .background(Color.background)
    .preferredColorScheme(.dark)
}

#Preview("Hug Button Interactive") {
    struct InteractivePreview: View {
        @State private var isHugged = false

        var body: some View {
            VStack(spacing: 20) {
                HugButton(isHugged: isHugged) {
                    isHugged.toggle()
                }

                Text(isHugged ? "Hugged!" : "Tap to hug")
                    .font(.appBody)
                    .foregroundStyle(.textSecondary)
            }
            .padding(40)
            .background(Color.background)
        }
    }

    return InteractivePreview()
        .preferredColorScheme(.dark)
}
