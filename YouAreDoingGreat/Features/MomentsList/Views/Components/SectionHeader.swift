import SwiftUI

// MARK: - Section Header Component
// Sticky header for date-based grouping in moments list

struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient.cosmic
                .opacity(0.95)
        )
    }
}

// MARK: - Preview

#Preview("Section Header") {
    VStack(spacing: 0) {
        SectionHeader(title: "Today")
        SectionHeader(title: "Yesterday")
        SectionHeader(title: "November 20, 2024")
    }
    .preferredColorScheme(.dark)
}
