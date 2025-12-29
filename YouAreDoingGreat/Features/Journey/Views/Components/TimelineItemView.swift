import SwiftUI

// MARK: - Timeline Item View
// Individual day summary card in the journey timeline

struct TimelineItemView: View {
    let item: DaySummaryDTO
    let isToday: Bool
    let isBeginning: Bool
    let isJourneyStart: Bool  // When true, "Journey begins" shows "Today" instead of date
    var descriptionText: String? = nil  // Optional description shown below "You are here"

    @State private var appear = false

    private var date: Date {
        DateFormatters.calendarDay(from: item.date) ?? Date()
    }

    private var day: String {
        DateFormatters.formatUTCComponent(item.date, format: "d")
    }

    private var month: String {
        DateFormatters.formatUTCComponent(item.date, format: "MMM").uppercased()
    }

    private var timeOfDayIcons: [String] {
        item.timesOfDay.compactMap { timeString in
            switch timeString {
            case "sunrise": return "sunrise"
            case "cloud-sun": return "cloud.sun"
            case "sun-medium", "sun.max": return "sun.max"
            case "sunset": return "sunset"
            case "moon": return "moon.stars"
            default: return nil
            }
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            // Left: Date column (or "Today" for journey start)
            if isBeginning && isJourneyStart {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.textSecondary)
                    .frame(width: 60)
                    .padding(.top, 8)
            } else {
                VStack(spacing: 4) {
                    Text(day)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.textPrimary)

                    Text(month)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.textTertiary)
                }
                .frame(width: 60)
                .padding(.top, 4)
            }

            // Middle: Timeline connector
            VStack(spacing: 0) {
                // Top line
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 12)

                // Dot
                ZStack {
                    if isToday {
                        todayDot
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.6))
                            .frame(width: 10, height: 10)
                    }
                }
                .frame(width: 32, height: 20)

                // Bottom line
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity)
            }
            .frame(width: 32)

            // Right: Content card
            if isToday {
                todayCard
                    .padding(.bottom, 24)
            } else if isBeginning {
                beginningCard
                    .padding(.bottom, 24)
            } else {
                contentCard
                    .padding(.bottom, 24)
            }
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                appear = true
            }
        }
    }

    // MARK: - Today Marker

    private var todayDot: some View {
        ZStack {
            // Pulsing outer ring
            Circle()
                .fill(Color.appPrimary.opacity(0.3))
                .frame(width: 20, height: 20)
                .scaleEffect(appear ? 1.4 : 1.0)
                .opacity(appear ? 0 : 0.6)
                .offset(y: appear ? 0 : -20)
                .animation(
                    .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: false),
                    value: appear
                )

            // Main dot
            Circle()
                .fill(Color.appPrimary)
                .frame(width: 12, height: 12)
                .shadow(color: Color.appPrimary.opacity(0.6), radius: 8)
        }
    }

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.appPrimary)

                Text("You are here")
                    .font(.appHeadline)
                    .foregroundStyle(.appPrimary)

                Spacer()

                // Show moments count if any
                if item.momentsCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))

                        Text("\(item.momentsCount)")
                            .font(.appFootnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.appPrimary.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.appPrimary.opacity(0.2))
                    )
                }
            }

            // Description text below "You are here"
            if let description = descriptionText {
                Text(description)
                    .font(.appCaption)
                    .foregroundStyle(.appPrimary.opacity(0.7))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appPrimary.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appPrimary.opacity(0.4), lineWidth: 1)
        )
    }

    private var beginningCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "flag.fill")
                .font(.system(size: 16))
                .foregroundStyle(.appSecondary)

            Text("Journey begins")
                .font(.appHeadline)
                .foregroundStyle(.appSecondary)

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSecondary.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.appSecondary.opacity(0.4), lineWidth: 1)
        )
    }

    // MARK: - Content Card

    private var contentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Moments count and time of day icons
            HStack {
                // Moments count badge
                if item.momentsCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))

                        Text("\(item.momentsCount)")
                            .font(.appFootnote)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                }

                Spacer()

                // Time of day icons
                if !timeOfDayIcons.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(timeOfDayIcons.prefix(3), id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.system(size: 14))
                                .foregroundStyle(.textTertiary)
                        }
                    }
                }
            }

            // Moment text
            if let text = item.text, !text.isEmpty {
                Text(text)
                    .font(.appBody)
                    .foregroundStyle(.textPrimary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("No moments for this day")
                    .font(.appBody)
                    .foregroundStyle(.textTertiary)
                    .italic()
            }

            // Tags
            if !item.tags.isEmpty {
                TagsView(tags: item.tags)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

// MARK: - Preview

#Preview("Timeline Items") {
    let calendar = Calendar.current
    let now = Date()

    let todayItem = DaySummaryDTO(
        id: "today",
        date: ISO8601DateFormatter().string(from: now),
        text: nil,
        tags: [],
        momentsCount: 3,
        timesOfDay: ["cloud-sun"],
        state: .inProgress,
        createdAt: ISO8601DateFormatter().string(from: now)
    )

    let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now)!
    let yesterdayItem = DaySummaryDTO(
        id: "yesterday",
        date: ISO8601DateFormatter().string(from: yesterdayDate),
        text: "Had a productive morning work session. Called my mom to check in.",
        tags: ["work", "family", "connection"],
        momentsCount: 2,
        timesOfDay: ["cloud-sun", "sunset"],
        state: .finalised,
        createdAt: ISO8601DateFormatter().string(from: yesterdayDate)
    )

    let twoDaysAgoDate = calendar.date(byAdding: .day, value: -2, to: now)!
    let twoDaysAgoItem = DaySummaryDTO(
        id: "twodays",
        date: ISO8601DateFormatter().string(from: twoDaysAgoDate),
        text: nil,
        tags: [],
        momentsCount: 0,
        timesOfDay: [],
        state: .finalised,
        createdAt: ISO8601DateFormatter().string(from: twoDaysAgoDate)
    )

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 0) {
                TimelineItemView(
                    item: todayItem,
                    isToday: true,
                    isBeginning: false,
                    isJourneyStart: false,
                    descriptionText: "Keep going. Today will come together."
                )
                TimelineItemView(item: yesterdayItem, isToday: false, isBeginning: false, isJourneyStart: false)
                TimelineItemView(item: twoDaysAgoItem, isToday: false, isBeginning: true, isJourneyStart: false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    .preferredColorScheme(.dark)
}

#Preview("Journey Just Started") {
    let now = Date()

    let todayItem = DaySummaryDTO(
        id: "today",
        date: ISO8601DateFormatter().string(from: now),
        text: nil,
        tags: [],
        momentsCount: 1,
        timesOfDay: ["cloud-sun"],
        state: .inProgress,
        createdAt: ISO8601DateFormatter().string(from: now)
    )

    let beginningItem = DaySummaryDTO(
        id: "beginning",
        date: ISO8601DateFormatter().string(from: now),
        text: nil,
        tags: [],
        momentsCount: 0,
        timesOfDay: [],
        state: .finalised,
        createdAt: ISO8601DateFormatter().string(from: now)
    )

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        ScrollView {
            VStack(spacing: 0) {
                TimelineItemView(
                    item: todayItem,
                    isToday: true,
                    isBeginning: false,
                    isJourneyStart: false,
                    descriptionText: "This is your timeline. Today will settle in by tomorrow."
                )
                TimelineItemView(item: beginningItem, isToday: false, isBeginning: true, isJourneyStart: true)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
        }
    }
    .preferredColorScheme(.dark)
}
