import SwiftUI

// MARK: - Cosmic Background View
// Reusable background with gradient, pattern overlay, and accent glows
// Used in LogMomentView, PraiseView, and MomentDetailSheet

struct CosmicBackgroundView: View {
    var body: some View {
        ZStack {
            // Base dark gradient
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.12, blue: 0.18),
                    Color(red: 0.06, green: 0.07, blue: 0.11)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Pattern overlay
            GeometryReader { geometry in
                Image("bg8")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            }
            .blendMode(.multiply)
            .opacity(0.4)

            // Top accent glow (purple)
            RadialGradient(
                colors: [
                    Color.appSecondary.opacity(0.2),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 400
            )

            // Subtle bottom accent (warm)
            RadialGradient(
                colors: [
                    Color.appPrimary.opacity(0.05),
                    Color.clear
                ],
                center: .bottom,
                startRadius: 0,
                endRadius: 300
            )
        }
    }
}

#Preview {
    CosmicBackgroundView()
        .ignoresSafeArea()
}
