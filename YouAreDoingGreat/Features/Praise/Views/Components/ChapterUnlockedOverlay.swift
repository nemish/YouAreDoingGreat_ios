import SwiftUI

// MARK: - Chapter Unlocked Overlay
// Celebration overlay shown when a new chapter is reached

struct ChapterUnlockedOverlay: View {
    let chapterName: String
    let chapter: Int

    @State private var isVisible = false
    @State private var particleScale: CGFloat = 0.5
    @State private var particleOpacity: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 16) {
            particleBurst
            chapterText
        }
        .padding(40)
        .background(cardBackground)
        .scaleEffect(isVisible ? 1 : 0.9)
        .opacity(isVisible ? 1 : 0)
        .onAppear {
            startAnimations()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("New chapter unlocked: \(chapterName), Chapter \(chapter)")
        .accessibilityAddTraits(.isStaticText)
    }

    // MARK: - Subviews

    private var particleBurst: some View {
        ZStack {
            ForEach(0..<12, id: \.self) { index in
                Circle()
                    .fill(index % 2 == 0 ? Color.appPrimary : Color.appSecondary)
                    .frame(width: 4, height: 4)
                    .offset(
                        x: cos(Double(index) * .pi / 6) * 50 * particleScale,
                        y: sin(Double(index) * .pi / 6) * 50 * particleScale
                    )
                    .opacity(particleOpacity)
            }
        }
        .frame(width: 120, height: 120)
    }

    private var chapterText: some View {
        VStack(spacing: 8) {
            Text("New Chapter Unlocked")
                .font(.appCaption)
                .foregroundStyle(.textSecondary)
                .textCase(.uppercase)
                .tracking(1.5)

            Text(chapterName)
                .font(.appTitle2)
                .foregroundStyle(Color.appPrimary)
                .multilineTextAlignment(.center)

            Text("Chapter \(chapter)")
                .font(.appBody)
                .foregroundStyle(.textTertiary)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color.backgroundTertiary.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.appPrimary.opacity(0.2), radius: 20)
    }

    // MARK: - Animations

    private func startAnimations() {
        // Entrance animation
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            isVisible = true
        }

        // Particle burst
        if !reduceMotion {
            withAnimation(.easeOut(duration: 0.8)) {
                particleScale = 1.5
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                particleOpacity = 0
            }
        }

        // Haptic
        Task { await HapticManager.shared.play(.warmArrival) }

        // Auto-dismiss after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.easeOut(duration: 0.3)) {
                isVisible = false
            }
        }
    }
}

// MARK: - Preview

#Preview("Chapter Unlocked") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        ChapterUnlockedOverlay(chapterName: "Growing Glow", chapter: 3)
    }
    .preferredColorScheme(.dark)
}
