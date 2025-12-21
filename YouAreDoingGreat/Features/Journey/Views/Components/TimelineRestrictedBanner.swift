import SwiftUI

// MARK: - Timeline Restricted Banner
// Shows a warm, supportive CTA when free users reach the 14-day limit

struct TimelineRestrictedBanner: View {
    let onUpgradeTapped: () -> Void

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            // Decorative icon with glow
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.appSecondary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .blur(radius: 20)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Main circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.appSecondary,
                                Color.appSecondary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)

                Image(systemName: "clock.badge.questionmark")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
            }

            // Title
            Text("Your journey continues...")
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            // Description
            Text("Free accounts show the last 14 days. Unlock your full history with premium.")
                .font(.appBody)
                .foregroundStyle(.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // CTA Button
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onUpgradeTapped()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 14, weight: .semibold))

                    Text("Unlock Full History")
                        .font(.appHeadline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.appPrimary, Color.appPrimary.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color.appPrimary.opacity(0.3), radius: 8, y: 4)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.backgroundSecondary.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.appSecondary.opacity(0.4),
                                    Color.appPrimary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Previews

#Preview("Timeline Restricted Banner") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        TimelineRestrictedBanner {
            print("Upgrade tapped")
        }
    }
    .preferredColorScheme(.dark)
}
