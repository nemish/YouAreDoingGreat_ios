import SwiftUI

// MARK: - User Stats Card
// Displays user statistics with glass-morphism design and staggered animations

struct UserStatsCard: View {
    let stats: UserStatsDTO
    let whisper: String

    @State private var isVisible = false

    var body: some View {
        ZStack {
            // Base glass background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.08))

            // Gradient overlay
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Content
            VStack(spacing: 16) {
                // Whisper text
                Text(whisper)
                    .font(.appCaption)
                    .foregroundStyle(Color.white.opacity(0.5))
                    .multilineTextAlignment(.center)

                // Stats row
                HStack(spacing: 0) {
                    Spacer()
                    StatItem(
                        icon: "flame.fill",
                        iconColor: Color(hex: "#FFA500"),
                        value: "\(stats.currentStreak)",
                        label: "Current\nStreak",
                        delay: 0.1
                    )

                    Spacer()

                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.6))

                    Spacer()

                    StatItem(
                        icon: "star.fill",
                        iconColor: Color(hex: "#FFD700"),
                        value: "\(stats.totalMoments)",
                        label: "Total\nMoments",
                        delay: 0.2
                    )

                    Spacer()

                    Divider()
                        .frame(height: 40)
                        .background(Color.white.opacity(0.6))

                    Spacer()

                    StatItem(
                        icon: "trophy.fill",
                        iconColor: Color(hex: "#C0C0C0"),
                        value: "\(stats.longestStreak)",
                        label: "Longest\nStreak",
                        delay: 0.3
                    )
                    Spacer()
                }
                .padding(.horizontal, 16)
            }
            .padding(.vertical, 24)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: 360)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.95)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Statistics. Current streak: \(stats.currentStreak) days. Total moments: \(stats.totalMoments). Longest streak: \(stats.longestStreak) days.")
    }
}

// MARK: - Stat Item

private struct StatItem: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let delay: Double

    @State private var isVisible = false
    @State private var iconScale: CGFloat = 0.5

    var body: some View {
        VStack(spacing: 6) {
            // Icon with spring animation
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .scaleEffect(iconScale)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(delay + 0.1)) {
                        iconScale = 1.0
                    }
                }

            // Value
            Text(value)
                .font(.gloriaHallelujah(32))
                .foregroundStyle(.textPrimary)

            // Label
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(Color.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .opacity(isVisible ? 1 : 0)
        .offset(y: isVisible ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(delay)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Preview

#Preview("User Stats Card") {
    VStack {
        Spacer()

        UserStatsCard(
            stats: UserStatsDTO(
                totalMoments: 127,
                momentsToday: 3,
                momentsYesterday: 2,
                currentStreak: 7,
                longestStreak: 14,
                lastMomentDate: nil
            ),
            whisper: "Every number here is a story you told yourself."
        )
        .padding(.horizontal, 24)

        Spacer()
    }
    .starfieldBackground()
    .preferredColorScheme(.dark)
}

#Preview("User Stats Card - Zero Stats") {
    VStack {
        Spacer()

        UserStatsCard(
            stats: UserStatsDTO(
                totalMoments: 0,
                momentsToday: 0,
                momentsYesterday: 0,
                currentStreak: 0,
                longestStreak: 0,
                lastMomentDate: nil
            ),
            whisper: "The fact you're tracking this means you care."
        )
        .padding(.horizontal, 24)

        Spacer()
    }
    .starfieldBackground()
    .preferredColorScheme(.dark)
}

#Preview("User Stats Card - Large Numbers") {
    VStack {
        Spacer()

        UserStatsCard(
            stats: UserStatsDTO(
                totalMoments: 999,
                momentsToday: 12,
                momentsYesterday: 8,
                currentStreak: 99,
                longestStreak: 365,
                lastMomentDate: nil
            ),
            whisper: "Little moments. Real effort. Honest wins."
        )
        .padding(.horizontal, 24)

        Spacer()
    }
    .starfieldBackground()
    .preferredColorScheme(.dark)
}
