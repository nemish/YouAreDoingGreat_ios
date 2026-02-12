import SwiftUI

// MARK: - Day State
// Defines the visual state of a day in the calendar

enum DayState: Equatable {
    case hasMoments(count: Int, daySummary: DaySummaryDTO)
    case pastEmpty
    case future
    case today
    case todayWithMoments(count: Int, daySummary: DaySummaryDTO)

    /// Compares by state kind and moment count only; `daySummary` is intentionally
    /// excluded because it doesn't affect the visual rendering of the circle
    /// (heat intensity and orbit dots depend solely on `count` and `timesOfDay`,
    /// which are derived from `count`). This avoids unnecessary SwiftUI diffing
    /// when the summary object changes but the visual output stays the same.
    static func == (lhs: DayState, rhs: DayState) -> Bool {
        switch (lhs, rhs) {
        case (.pastEmpty, .pastEmpty), (.future, .future), (.today, .today):
            return true
        case let (.hasMoments(count1, _), .hasMoments(count2, _)):
            return count1 == count2
        case let (.todayWithMoments(count1, _), .todayWithMoments(count2, _)):
            return count1 == count2
        default:
            return false
        }
    }
}

// MARK: - Day Circle View
// Individual day circle component for the month calendar grid

struct DayCircleView: View {
    let date: Date
    let state: DayState
    let onTap: ((DaySummaryDTO) -> Void)?

    private let circleSize: CGFloat = 40
    private let orbitDotSize: CGFloat = 5
    private let dotGap: CGFloat = 2
    private let orbitRadius: CGFloat = 25
    private let totalSize: CGFloat = 48

    private var isTappable: Bool {
        switch state {
        case .hasMoments, .todayWithMoments:
            return true
        default:
            return false
        }
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    /// Number of moments for the current day
    private var momentCount: Int {
        switch state {
        case .hasMoments(let count, _), .todayWithMoments(let count, _):
            return count
        default:
            return 0
        }
    }

    /// Colors for orbit dots — one per moment, cycling through timesOfDay colors
    private var dotColors: [Color] {
        guard momentCount > 0 else { return [] }
        switch state {
        case .hasMoments(_, let summary), .todayWithMoments(_, let summary):
            let timeColors = summary.timesOfDay.map { colorForTimeOfDay($0) }
            if timeColors.isEmpty {
                return Array(repeating: Color.appPrimary.opacity(0.6), count: momentCount)
            }
            return (0..<momentCount).map { timeColors[$0 % timeColors.count] }
        default:
            return []
        }
    }

    var body: some View {
        Button {
            handleTap()
        } label: {
            ZStack {
                circleBackground
                contentView
                orbitDotsView
            }
            .frame(width: totalSize, height: totalSize)
        }
        .buttonStyle(.plain)
        .disabled(!isTappable)
    }

    // MARK: - Heat Intensity

    /// Heat intensity: darker (but visible) for few moments, brighter for many
    /// Range: 0.45 (1 moment) → 0.90 (5+ moments)
    private func heatIntensity(for count: Int) -> Double {
        min(0.45 + Double(count - 1) * 0.11, 0.90)
    }

    // MARK: - Time of Day Color

    /// Maps API time-of-day string to the corresponding accent color
    private func colorForTimeOfDay(_ timeString: String) -> Color {
        switch timeString {
        case "sunrise":
            return Color(red: 0x2a / 255, green: 0x9d / 255, blue: 0x8f / 255) // Teal
        case "cloud-sun":
            return Color(red: 0x00 / 255, green: 0x77 / 255, blue: 0xb6 / 255) // Blue
        case "sun-medium", "sun.max":
            return Color(red: 0xe7 / 255, green: 0x6f / 255, blue: 0x51 / 255) // Orange
        case "sunset":
            return Color(red: 0xae / 255, green: 0x20 / 255, blue: 0x12 / 255) // Red
        case "moon":
            return Color(red: 0x00 / 255, green: 0x35 / 255, blue: 0x66 / 255) // Dark blue
        default:
            return .textTertiary
        }
    }

    // MARK: - Circle Background

    @ViewBuilder
    private var circleBackground: some View {
        switch state {
        case .hasMoments(let count, _):
            let intensity = heatIntensity(for: count)
            Circle()
                .fill(Color.appPrimary.opacity(intensity))
                .shadow(color: Color.appPrimary.opacity(intensity * 0.4), radius: 4)
                .frame(width: circleSize, height: circleSize)

        case .todayWithMoments(let count, _):
            let intensity = heatIntensity(for: count)
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(intensity))
                    .shadow(color: Color.appPrimary.opacity(intensity * 0.5), radius: 6)
                Circle()
                    .strokeBorder(Color.appPrimary, lineWidth: 2)
            }
            .frame(width: circleSize, height: circleSize)

        case .today:
            Circle()
                .strokeBorder(Color.appPrimary, lineWidth: 2)
                .frame(width: circleSize, height: circleSize)

        case .future:
            Circle()
                .stroke(
                    Color.textTertiary.opacity(0.4),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
                .frame(width: circleSize, height: circleSize)

        case .pastEmpty:
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: circleSize, height: circleSize)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        switch state {
        case .hasMoments:
            Text(dayNumber)
                .font(.appCaption)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

        case .todayWithMoments:
            Text(dayNumber)
                .font(.appCaption)
                .fontWeight(.bold)
                .foregroundStyle(.white)

        case .today:
            Text(dayNumber)
                .font(.appCaption)
                .foregroundStyle(.appPrimary)

        case .pastEmpty:
            Text(dayNumber)
                .font(.appCaption)
                .foregroundStyle(.textSecondary)

        case .future:
            Text(dayNumber)
                .font(.appCaption)
                .foregroundStyle(.textTertiary.opacity(0.6))
        }
    }

    // MARK: - Orbit Dots

    @ViewBuilder
    private var orbitDotsView: some View {
        let colors = dotColors
        if !colors.isEmpty {
            // Angular step between dot centers along the arc
            let angularStep = (orbitDotSize + dotGap) / orbitRadius
            let count = colors.count
            // Total arc span, centered at top (-π/2)
            let totalSpan = angularStep * CGFloat(count - 1)
            let startAngle = -.pi / 2 - totalSpan / 2

            ForEach(0..<count, id: \.self) { index in
                let angle = startAngle + angularStep * CGFloat(index)
                let x = orbitRadius * cos(angle)
                let y = orbitRadius * sin(angle)

                Circle()
                    .fill(colors[index])
                    .frame(width: orbitDotSize, height: orbitDotSize)
                    .offset(x: x, y: y)
            }
        }
    }

    // MARK: - Actions

    private func handleTap() {
        switch state {
        case .hasMoments(_, let summary), .todayWithMoments(_, let summary):
            Task { await HapticManager.shared.play(.gentleTap) }
            onTap?(summary)
        default:
            break
        }
    }
}

// MARK: - Preview

#Preview("Day States") {
    let formatter = ISO8601DateFormatter()
    let today = Date()
    let calendar = Calendar.current

    func mockSummary(count: Int, times: [String]) -> DaySummaryDTO {
        DaySummaryDTO(
            id: "mock-\(count)",
            date: formatter.string(from: today),
            text: "Great day!",
            tags: ["work"],
            momentsCount: count,
            timesOfDay: times,
            state: .finalised,
            createdAt: formatter.string(from: today)
        )
    }

    return ZStack {
        LinearGradient.cosmic
            .ignoresSafeArea()

        VStack(spacing: 24) {
            Text("Heat Intensity + Time Dots")
                .font(.appTitle3)
                .foregroundStyle(.textPrimary)

            // Heat intensity levels with varying time-of-day dots
            HStack(spacing: 8) {
                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: -1, to: today)!,
                        state: .hasMoments(count: 1, daySummary: mockSummary(count: 1, times: ["cloud-sun"])),
                        onTap: nil
                    )
                    Text("1")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: -2, to: today)!,
                        state: .hasMoments(count: 2, daySummary: mockSummary(count: 2, times: ["cloud-sun", "sunset"])),
                        onTap: nil
                    )
                    Text("2")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: -3, to: today)!,
                        state: .hasMoments(count: 3, daySummary: mockSummary(count: 3, times: ["sunrise", "cloud-sun", "moon"])),
                        onTap: nil
                    )
                    Text("3")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: -4, to: today)!,
                        state: .hasMoments(count: 5, daySummary: mockSummary(count: 5, times: ["sunrise", "cloud-sun", "sun.max", "sunset", "moon"])),
                        onTap: nil
                    )
                    Text("5")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    DayCircleView(
                        date: today,
                        state: .todayWithMoments(count: 3, daySummary: mockSummary(count: 3, times: ["cloud-sun", "sun.max"])),
                        onTap: nil
                    )
                    Text("Today + moments")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                VStack(spacing: 8) {
                    DayCircleView(
                        date: today,
                        state: .today,
                        onTap: nil
                    )
                    Text("Today empty")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: -5, to: today)!,
                        state: .pastEmpty,
                        onTap: nil
                    )
                    Text("Past empty")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }

                VStack(spacing: 8) {
                    DayCircleView(
                        date: calendar.date(byAdding: .day, value: 3, to: today)!,
                        state: .future,
                        onTap: nil
                    )
                    Text("Future")
                        .font(.appCaption)
                        .foregroundStyle(.textSecondary)
                }
            }
        }
    }
    .preferredColorScheme(.dark)
}
