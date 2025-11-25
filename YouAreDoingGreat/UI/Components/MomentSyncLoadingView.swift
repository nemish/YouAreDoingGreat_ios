import SwiftUI

// MARK: - Moment Sync Loading View
// Composed loading indicator for moment synchronization
// Combines animated blob orb with rotating text phrases

struct MomentSyncLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Animated blob orb with particle orbits
            AnimatedBlobOrb()

            // Rotating encouraging text
            RotatingLoadingText()
        }
    }
}

// MARK: - Preview

#Preview("Moment Sync Loading") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        MomentSyncLoadingView()
    }
    .preferredColorScheme(.dark)
}
