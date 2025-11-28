import SwiftUI

// MARK: - Moment Card Component
// Displays a single moment with text, praise, tags, and metadata

struct MomentCard: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Time + Icons
            HStack {
                Text(timeDisplayText)
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)

                Spacer()

                HStack(spacing: 8) {
                    if !moment.isSynced {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(.textTertiary)
                    }

                    if moment.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(.appPrimary)
                    }
                }
            }
            .padding(.bottom, 12)

            // Moment text
            Text(moment.text)
                .font(.appBody)
                .foregroundStyle(.textPrimary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            // Tags
            if !moment.tags.isEmpty {
                TagsView(tags: moment.tags)
                    .padding(.top, 12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }

    private var timeDisplayText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: moment.happenedAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Moment Card") {
    ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        MomentCard(
            moment: Moment(
                text: "Finished that thing I was putting off for weeks",
                submittedAt: Date(),
                happenedAt: Date().addingTimeInterval(-3600),
                timezone: TimeZone.current.identifier,
                timeAgo: 3600,
                offlinePraise: "Nice. You're making moves."
            )
        )
        .padding()
    }
    .preferredColorScheme(.dark)
}
