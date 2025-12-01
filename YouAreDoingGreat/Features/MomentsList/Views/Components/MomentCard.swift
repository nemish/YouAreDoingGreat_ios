import SwiftUI

// MARK: - Moment Card Component
// Displays a single moment with text, praise, tags, and metadata

struct MomentCard: View {
    let moment: Moment
    let isHighlighted: Bool

    @State private var glowIntensity: CGFloat = 0

    private var timeOfDay: TimeOfDay {
        TimeOfDay(from: moment.happenedAt)
    }

    init(moment: Moment, isHighlighted: Bool = false) {
        self.moment = moment
        self.isHighlighted = isHighlighted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header: Time + Icons
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: timeOfDay.iconName)
                        .font(.system(size: 12))
                        .foregroundStyle(timeOfDay.accentColor)

                    Text(timeDisplayText)
                        .font(.appCaption)
                        .foregroundStyle(.textTertiary)
                }

                Spacer()

                HStack(spacing: 8) {
                    // Enrichment status indicator
                    if moment.serverId != nil && !moment.isSynced {
                        // Has serverId but not synced = enriching
                        if let praise = moment.praise, !praise.isEmpty {
                            // Just enriched - show checkmark briefly
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                                .symbolEffect(.bounce, value: moment.praise)
                        } else {
                            // Enriching in progress
                            Image(systemName: "sparkles")
                                .font(.system(size: 12))
                                .foregroundStyle(.appPrimary)
                                .symbolEffect(.pulse, options: .repeating)
                        }
                    } else if moment.serverId == nil && !moment.isSynced {
                        // No serverId yet = creating on server
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 12))
                            .foregroundStyle(.textTertiary)
                            .symbolEffect(.pulse, options: .repeating)
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
                .fill(timeOfDay.backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(timeOfDay.borderColor, lineWidth: 1)
        )
        .shadow(
            color: isHighlighted ? timeOfDay.accentColor.opacity(glowIntensity) : .clear,
            radius: isHighlighted ? 20 : 0
        )
        .scaleEffect(isHighlighted ? 1 + (glowIntensity * 0.02) : 1)
        .onAppear {
            if isHighlighted {
                startHighlightAnimation()
            }
        }
    }

    private func startHighlightAnimation() {
        // Pulse animation - 2 complete cycles (in/out/in/out)
        withAnimation(.easeInOut(duration: 0.6).repeatCount(2, autoreverses: true)) {
            glowIntensity = 0.8
        }

        // Reset to normal state after animation completes
        Task {
            try? await Task.sleep(for: .seconds(0.6 * 2 * 2)) // 2 cycles × 2 (in/out) × 0.6s = 2.4s
            withAnimation(.easeOut(duration: 0.3)) {
                glowIntensity = 0
            }
        }
    }

    private var timeDisplayText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: moment.happenedAt, relativeTo: Date())
    }
}

// MARK: - Preview

#Preview("Moment Card - All Times of Day") {
    let calendar = Calendar.current
    let now = Date()

    // Create moments for different times of day
    let earlyMorningDate = calendar.date(bySettingHour: 6, minute: 30, second: 0, of: now)!
    let morningDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!
    let afternoonDate = calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now)!
    let eveningDate = calendar.date(bySettingHour: 18, minute: 45, second: 0, of: now)!
    let nightDate = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: now)!

    let moments = [
        Moment(
            text: "Watched the sunrise while drinking coffee",
            submittedAt: earlyMorningDate,
            happenedAt: earlyMorningDate,
            timezone: TimeZone.current.identifier,
            timeAgo: 0,
            offlinePraise: "Nice. You're making moves."
        ),
        Moment(
            text: "Had a productive morning work session",
            submittedAt: morningDate,
            happenedAt: morningDate,
            timezone: TimeZone.current.identifier,
            timeAgo: 0,
            offlinePraise: "That's it. Small stuff adds up."
        ),
        Moment(
            text: "Went for a walk in the sunshine",
            submittedAt: afternoonDate,
            happenedAt: afternoonDate,
            timezone: TimeZone.current.identifier,
            timeAgo: 0,
            offlinePraise: "Look at you showing up."
        ),
        Moment(
            text: "Called my mom to check in",
            submittedAt: eveningDate,
            happenedAt: eveningDate,
            timezone: TimeZone.current.identifier,
            timeAgo: 0,
            offlinePraise: "You did that. Nice."
        ),
        Moment(
            text: "Read a few chapters before bed",
            submittedAt: nightDate,
            happenedAt: nightDate,
            timezone: TimeZone.current.identifier,
            timeAgo: 0,
            offlinePraise: "Small wins count too."
        ),
    ]

    // Add tags and favorite to some
    moments[0].tags = ["self-care", "morning"]
    moments[2].tags = ["exercise", "outdoors"]
    moments[2].isFavorite = true
    moments[3].tags = ["family", "connection"]
    moments[4].isSynced = false

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 12) {
                ForEach(moments) { moment in
                    MomentCard(moment: moment)
                }
            }
            .padding()
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Moment Card - Highlighted") {
    let calendar = Calendar.current
    let now = Date()

    // Create a highlighted moment at morning time
    let morningDate = calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!

    let highlightedMoment = Moment(
        text: "Just finished an important work presentation! Feeling accomplished.",
        submittedAt: morningDate,
        happenedAt: morningDate,
        timezone: TimeZone.current.identifier,
        timeAgo: 0,
        offlinePraise: "That's it. Small stuff adds up."
    )
    highlightedMoment.tags = ["work", "achievement"]
    highlightedMoment.isSynced = true

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Highlighted Card")
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)

            MomentCard(moment: highlightedMoment, isHighlighted: true)
                .padding(.horizontal)

            Text("Normal Card")
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)

            MomentCard(moment: highlightedMoment, isHighlighted: false)
                .padding(.horizontal)
        }
    }
    .preferredColorScheme(.dark)
}
