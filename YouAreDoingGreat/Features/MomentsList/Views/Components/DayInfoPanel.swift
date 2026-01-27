import SwiftUI

// MARK: - Day Info Panel
// Hero panel displaying day overview: times of day, summary, and tags
// Designed to collapse on scroll for efficient space usage

struct DayInfoPanel: View {
    let daySummary: DaySummaryDTO
    let isCollapsed: Bool
    var onTagTap: ((String) -> Void)? = nil

    // Mapped icon data with colors
    private struct TimeOfDayIcon {
        let iconName: String
        let color: Color
    }

    private var timeOfDayIcons: [TimeOfDayIcon] {
        daySummary.timesOfDay.compactMap { timeString in
            switch timeString {
            case "sunrise":
                return TimeOfDayIcon(
                    iconName: "sunrise.fill",
                    color: Color(red: 0x2a / 255, green: 0x9d / 255, blue: 0x8f / 255) // Teal
                )
            case "cloud-sun":
                return TimeOfDayIcon(
                    iconName: "cloud.sun.fill",
                    color: Color(red: 0x00 / 255, green: 0x77 / 255, blue: 0xb6 / 255) // Blue
                )
            case "sun-medium", "sun.max":
                return TimeOfDayIcon(
                    iconName: "sun.max.fill",
                    color: Color(red: 0xe7 / 255, green: 0x6f / 255, blue: 0x51 / 255) // Orange
                )
            case "sunset":
                return TimeOfDayIcon(
                    iconName: "sunset.fill",
                    color: Color(red: 0xae / 255, green: 0x20 / 255, blue: 0x12 / 255) // Red
                )
            case "moon":
                return TimeOfDayIcon(
                    iconName: "moon.stars.fill",
                    color: Color(red: 0x00 / 255, green: 0x35 / 255, blue: 0x66 / 255) // Dark blue
                )
            default:
                return nil
            }
        }
    }

    var body: some View {
        if isCollapsed {
            collapsedHeader
        } else {
            expandedPanel
        }
    }

    // MARK: - Collapsed Header

    private var collapsedHeader: some View {
        HStack {
            Text(formattedDayOfWeek)
                .font(.appHeadline)
                .foregroundStyle(.textPrimary)

            Spacer()

            if !timeOfDayIcons.isEmpty {
                HStack(spacing: 8) {
                    ForEach(Array(timeOfDayIcons.prefix(3).enumerated()), id: \.offset) { _, icon in
                        Image(systemName: icon.iconName)
                            .font(.system(size: 16))
                            .foregroundStyle(icon.color)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    // MARK: - Expanded Hero Panel

    private var expandedPanel: some View {
        VStack(spacing: 16) {
            // Times of day - large icons with colors
            if !timeOfDayIcons.isEmpty {
                HStack(spacing: 24) {
                    ForEach(Array(timeOfDayIcons.enumerated()), id: \.offset) { _, icon in
                        Image(systemName: icon.iconName)
                            .font(.system(size: 36))
                            .foregroundStyle(icon.color)
                    }
                }
            }

            // Day summary text
            if let summaryText = daySummary.text, !summaryText.isEmpty {
                Text(summaryText)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .lineSpacing(4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Tags section
            if !daySummary.tags.isEmpty {
                FlowLayout(horizontalSpacing: 6, verticalSpacing: 6) {
                    ForEach(daySummary.tags, id: \.self) { tag in
                        TagPill(tag: tag, onTap: onTagTap)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private var formattedDayOfWeek: String {
        guard let date = DateFormatters.calendarDay(from: daySummary.date) else {
            return daySummary.date
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Tag Pill Component (reused from TagsView)

private struct TagPill: View {
    let tag: String
    var onTap: ((String) -> Void)? = nil

    var body: some View {
        let content = Text("#\(tag.replacingOccurrences(of: "_", with: " "))")
            .font(.appCaption)
            .foregroundStyle(.appSecondary)
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.appSecondary.opacity(0.2))
            )

        if let onTap = onTap {
            Button {
                Task { await HapticManager.shared.play(.gentleTap) }
                onTap(tag)
            } label: {
                content
            }
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview("Day Info Panel") {
    let daySummary = DaySummaryDTO(
        id: "2026-01-03",
        date: "2026-01-03",
        text: "Productive morning with work and self-care moments throughout the day",
        tags: ["work", "self_care", "productivity", "health"],
        momentsCount: 5,
        timesOfDay: ["sunrise", "sun-medium", "moon"],
        state: .finalised,
        createdAt: "2026-01-03T12:00:00Z"
    )

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 20) {
            Text("Expanded State")
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)

            DayInfoPanel(
                daySummary: daySummary,
                isCollapsed: false,
                onTagTap: { tag in
                    print("Tapped tag: \(tag)")
                }
            )

            Text("Collapsed State")
                .font(.appTitle3)
                .foregroundStyle(.textSecondary)
                .padding(.top, 20)

            DayInfoPanel(
                daySummary: daySummary,
                isCollapsed: true
            )

            Spacer()
        }
    }
    .preferredColorScheme(.dark)
}
