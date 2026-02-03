import Foundation

/// Calculates week numbers for moments based on an epoch date
/// Week 0 is the week containing the first moment (epoch)
/// Each subsequent week is 7 days from the epoch
struct WeekCalculator {
    private let epochDate: Date

    init(epochDate: Date) {
        // Normalize to start of day for consistency
        self.epochDate = Calendar.current.startOfDay(for: epochDate)
    }

    /// Calculate week number for a given moment date
    /// - Parameter date: The moment's happenedAt date
    /// - Returns: Week number (0-based, Week 0 = epoch week)
    func weekNumber(for date: Date) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)

        let components = calendar.dateComponents(
            [.day],
            from: epochDate,
            to: startOfDay
        )

        guard let days = components.day else { return 0 }

        // Clamp to minimum of Week 0 (handle backdated moments)
        return max(0, days / 7)
    }
}
