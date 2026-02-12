import SwiftUI

// MARK: - Month Navigation View
// Swipeable container for navigating between months

struct MonthNavigationView: View {
    let timelineItems: [DaySummaryDTO]
    let earliestDate: Date?

    @State private var selectedMonthIndex: Int = 0
    @State private var hasInitialized = false
    @State private var dragOffset: CGFloat = 0

    /// Generate array of months from earliest to current
    private var availableMonths: [Date] {
        let calendar = Calendar.current
        let currentMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: Date()))!

        guard let earliest = earliestDate,
              let startMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: earliest)) else {
            return [currentMonth]
        }

        var months: [Date] = []
        var current = startMonth

        // Build months from earliest to current
        while current <= currentMonth {
            months.append(current)
            guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: current) else { break }
            current = nextMonth
        }

        return months
    }

    var body: some View {
        GeometryReader { geometry in
            // Calendar content
            HStack(spacing: 0) {
                    ForEach(Array(availableMonths.enumerated()), id: \.offset) { index, month in
                        MonthCalendarView(
                            selectedMonth: month,
                            timelineItems: timelineItems,
                            earliestDate: earliestDate
                        )
                        .frame(width: geometry.size.width)
                    }
                }
                .offset(x: -CGFloat(selectedMonthIndex) * geometry.size.width + dragOffset)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedMonthIndex)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onChanged { value in
                            // Only allow horizontal drag
                            if abs(value.translation.width) > abs(value.translation.height) {
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            let threshold: CGFloat = geometry.size.width * 0.25
                            let horizontalAmount = value.translation.width

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if horizontalAmount < -threshold && selectedMonthIndex < availableMonths.count - 1 {
                                    // Swipe left -> next month
                                    selectedMonthIndex += 1
                                    Task { await HapticManager.shared.play(.gentleTap) }
                                } else if horizontalAmount > threshold && selectedMonthIndex > 0 {
                                    // Swipe right -> previous month
                                    selectedMonthIndex -= 1
                                    Task { await HapticManager.shared.play(.gentleTap) }
                                }
                                dragOffset = 0
                            }
                        }
                )
                .onAppear {
                    // Start at current month (last in array) only on first appear
                    if !hasInitialized {
                        selectedMonthIndex = max(0, availableMonths.count - 1)
                        hasInitialized = true
                    }
                }
        }
        .overlay {
            GeometryReader { geo in
                Image("bg5")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height * 0.75)
                    .clipped()
                    .frame(width: geo.size.width, height: geo.size.height, alignment: .bottom)
            }
            .mask(
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0.3),
                        .init(color: .white, location: 0.9),
                        .init(color: .white, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blendMode(.colorDodge)
            .opacity(0.2)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Preview

#Preview("Month Navigation") {
    let calendar = Calendar.current
    let now = Date()
    let formatter = ISO8601DateFormatter()

    // Create mock items spanning 3 months
    var mockItems: [DaySummaryDTO] = []

    // Current month items
    mockItems.append(DaySummaryDTO(
        id: "today",
        date: formatter.string(from: now),
        text: nil,
        tags: [],
        momentsCount: 2,
        timesOfDay: ["cloud-sun"],
        state: .inProgress,
        createdAt: formatter.string(from: now)
    ))

    mockItems.append(DaySummaryDTO(
        id: "yesterday",
        date: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!),
        text: "Great day!",
        tags: ["work"],
        momentsCount: 3,
        timesOfDay: ["sun.max"],
        state: .finalised,
        createdAt: formatter.string(from: calendar.date(byAdding: .day, value: -1, to: now)!)
    ))

    // Last month items
    let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
    mockItems.append(DaySummaryDTO(
        id: "lastmonth1",
        date: formatter.string(from: lastMonth),
        text: "Good workout.",
        tags: ["fitness"],
        momentsCount: 2,
        timesOfDay: ["sunrise"],
        state: .finalised,
        createdAt: formatter.string(from: lastMonth)
    ))

    // Two months ago items
    let twoMonthsAgo = calendar.date(byAdding: .month, value: -2, to: now)!
    mockItems.append(DaySummaryDTO(
        id: "twomonthsago1",
        date: formatter.string(from: twoMonthsAgo),
        text: "Started my journey.",
        tags: ["beginning"],
        momentsCount: 1,
        timesOfDay: ["moon"],
        state: .finalised,
        createdAt: formatter.string(from: twoMonthsAgo)
    ))

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        MonthNavigationView(
            timelineItems: mockItems,
            earliestDate: twoMonthsAgo
        )
    }
    .preferredColorScheme(.dark)
}
