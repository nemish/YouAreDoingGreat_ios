import SwiftUI

// MARK: - Month Calendar View
// Single month calendar grid showing days with moment counts

struct MonthCalendarView: View {
    let selectedMonth: Date
    let timelineItems: [DaySummaryDTO]
    let earliestDate: Date?

    @State private var selectedDay: SelectedDay?

    /// Wrapper to make the selected day identifiable for sheet presentation
    private struct SelectedDay: Identifiable {
        let id = UUID()
        let date: Date
        let daySummary: DaySummaryDTO?
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 7)

    /// Weekday symbols rotated to start from the calendar's first day of week
    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.shortWeekdaySymbols
        let firstWeekday = calendar.firstWeekday // 1 = Sunday, 2 = Monday, etc.
        // Rotate symbols so they start from firstWeekday
        return Array(symbols[(firstWeekday - 1)...]) + Array(symbols[..<(firstWeekday - 1)])
    }

    var body: some View {
        VStack(spacing: 16) {
            // Month title header
            Text(monthTitle)
                .font(.appTitle2)
                .foregroundStyle(.textPrimary)
                .padding(.top, 0)

            // Weekday header
            weekdayHeader

            // Calendar grid
            calendarGrid

            Spacer()
        }
        .sheet(item: $selectedDay) { day in
            FilteredMomentsListView(
                date: day.date,
                daySummary: day.daySummary,
                viewModel: nil
            )
        }
    }

    // MARK: - Month Title

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    // MARK: - Weekday Header

    private var weekdayHeader: some View {
        HStack {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(String(symbol.prefix(1)))
                    .font(.appCaption)
                    .foregroundStyle(.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            // Leading empty cells for alignment (no circles rendered)
            ForEach(0..<leadingPaddingDays, id: \.self) { _ in
                Color.clear
                    .frame(width: 48, height: 48)
            }

            // Actual days of the month
            ForEach(daysInMonth, id: \.self) { date in
                DayCircleView(
                    date: date,
                    state: dayState(for: date),
                    onTap: { summary in
                        selectedDay = SelectedDay(date: date, daySummary: summary)
                    }
                )
            }

            // No trailing cells - grid naturally ends after the last day
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Calendar Calculations

    /// Generate all days for the selected month
    private var daysInMonth: [Date] {
        let calendar = Calendar.current

        guard let range = calendar.range(of: .day, in: .month, for: selectedMonth),
              let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return []
        }

        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }

    /// Calculate padding days for week alignment (empty leading cells)
    /// Respects the calendar's firstWeekday setting (e.g., Monday-first locales)
    private var leadingPaddingDays: Int {
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: selectedMonth)) else {
            return 0
        }
        // weekday: 1 = Sunday, 2 = Monday, ..., 7 = Saturday
        let weekday = calendar.component(.weekday, from: startOfMonth)
        // firstWeekday: 1 = Sunday, 2 = Monday, etc. (based on locale)
        let firstWeekday = calendar.firstWeekday
        // Calculate offset from the first column
        var padding = weekday - firstWeekday
        if padding < 0 {
            padding += 7
        }
        return padding
    }

    /// Determine the visual state for a given date
    private func dayState(for date: Date) -> DayState {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let targetDay = calendar.startOfDay(for: date)

        let isToday = calendar.isDateInToday(date)
        let isFuture = targetDay > today

        // Check if we have data for this day
        if let daySummary = findDaySummary(for: date) {
            if isToday {
                return .todayWithMoments(count: daySummary.momentsCount, daySummary: daySummary)
            }
            return .hasMoments(count: daySummary.momentsCount, daySummary: daySummary)
        }

        if isToday { return .today }
        if isFuture { return .future }
        return .pastEmpty
    }

    /// Find day summary for a specific date
    /// Matches by day number components: API date in UTC vs calendar grid date in local
    /// This ensures the month view shows the same days as the timeline (both UTC-based)
    private func findDaySummary(for date: Date) -> DaySummaryDTO? {
        let localCalendar = Calendar.current
        let target = localCalendar.dateComponents([.year, .month, .day], from: date)

        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt

        for item in timelineItems {
            if let itemDate = DateFormatters.parseISO8601(item.date) {
                let itemComponents = utcCalendar.dateComponents([.year, .month, .day], from: itemDate)
                if target.year == itemComponents.year &&
                   target.month == itemComponents.month &&
                   target.day == itemComponents.day {
                    if item.momentsCount > 0 {
                        return item
                    }
                }
            }
        }
        return nil
    }
}

// MARK: - Preview

#Preview("Month Calendar") {
    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    let mockItems = [
        DaySummaryDTO(
            id: "0",
            date: formatter.string(from: now),
            text: nil,
            tags: [],
            momentsCount: 2,
            timesOfDay: ["cloud-sun"],
            state: .inProgress,
            createdAt: formatter.string(from: now)
        ),
        DaySummaryDTO(
            id: "1",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
            text: "Had a productive day.",
            tags: ["work", "family"],
            momentsCount: 3,
            timesOfDay: ["cloud-sun", "sunset"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
        ),
        DaySummaryDTO(
            id: "2",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!),
            text: "Went for a walk.",
            tags: ["exercise"],
            momentsCount: 1,
            timesOfDay: ["sun.max"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -3, to: now)!)
        ),
        DaySummaryDTO(
            id: "3",
            date: formatter.string(from: calendar.date(byAdding: .day, value: -7, to: now)!),
            text: "Great workout!",
            tags: ["fitness"],
            momentsCount: 4,
            timesOfDay: ["sunrise", "cloud-sun"],
            state: .finalised,
            createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -7, to: now)!)
        ),
    ]

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        MonthCalendarView(
            selectedMonth: now,
            timelineItems: mockItems,
            earliestDate: calendar.date(byAdding: .day, value: -7, to: now)
        )
    }
    .preferredColorScheme(.dark)
}
