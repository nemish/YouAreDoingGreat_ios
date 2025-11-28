import SwiftUI

// MARK: - Stat Card Component
// Reusable card for displaying user statistics

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.appPrimary)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.appFootnote)
                    .foregroundStyle(.textSecondary)

                Text(value)
                    .font(.appCallout)
                    .foregroundStyle(.textPrimary)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview("Stat Card") {
    VStack(spacing: 12) {
        StatCard(
            icon: "sparkles",
            label: "Total Moments",
            value: "127"
        )

        StatCard(
            icon: "calendar",
            label: "Today",
            value: "3"
        )

        StatCard(
            icon: "flame.fill",
            label: "Current Streak",
            value: "7 days"
        )
    }
    .padding(24)
    .starfieldBackground()
    .preferredColorScheme(.dark)
}
