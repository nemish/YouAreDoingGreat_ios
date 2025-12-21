import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "paywall")

// MARK: - Paywall Trigger
// Identifies why the paywall is being shown

enum PaywallTrigger {
    case dailyLimitReached
    case totalLimitReached
    case timelineRestricted
    case manualTrigger
}

// MARK: - Paywall Service
// Manages daily limit state and determines when to show paywall

@MainActor
@Observable
final class PaywallService {
    // Singleton instance
    static let shared = PaywallService()

    // Paywall presentation state
    var shouldShowPaywall: Bool = false
    var dailyLimitReachedDate: Date?
    var paywallTrigger: PaywallTrigger = .manualTrigger

    // Timeline restriction state
    var isTimelineRestricted: Bool = false

    // Total limit state (permanent until premium upgrade)
    var isTotalLimitReached: Bool = false

    // UserDefaults keys
    private let dailyLimitDateKey = "com.youaredoinggreat.dailyLimitDate"
    private let totalLimitReachedKey = "com.youaredoinggreat.totalLimitReached"

    private init() {
        loadState()
        checkIfNewDay()
    }

    // MARK: - Public Methods

    /// Check if daily limit has been reached
    var isDailyLimitReached: Bool {
        guard let limitDate = dailyLimitReachedDate else {
            return false
        }

        // Check if we're still on the same day
        return isSameDay(limitDate, Date())
    }

    /// Mark that daily limit has been reached
    func markDailyLimitReached() {
        let now = Date()
        dailyLimitReachedDate = now
        paywallTrigger = .dailyLimitReached
        saveState()

        logger.info("Daily limit reached, paywall activated until next day")
    }

    /// Mark that total limit has been reached (permanent until premium upgrade)
    func markTotalLimitReached() {
        isTotalLimitReached = true
        paywallTrigger = .totalLimitReached
        saveState()

        logger.info("Total limit reached, paywall activated permanently until upgrade")
    }

    /// Check if user should see paywall (called before logging moment)
    func shouldBlockMomentCreation() -> Bool {
        checkIfNewDay()

        // Premium users bypass all limits
        if SubscriptionService.shared.hasActiveSubscription {
            return false
        }

        // Check total limit first (more permanent)
        if isTotalLimitReached {
            return true
        }

        return isDailyLimitReached
    }

    /// Show the paywall (preserves existing trigger if set by mark* methods)
    func showPaywall(trigger: PaywallTrigger? = nil) {
        if let trigger = trigger {
            paywallTrigger = trigger
        }
        // Only set to manualTrigger if no limit trigger is active
        else if paywallTrigger != .dailyLimitReached &&
                paywallTrigger != .totalLimitReached &&
                paywallTrigger != .timelineRestricted {
            paywallTrigger = .manualTrigger
        }
        shouldShowPaywall = true
    }

    /// Dismiss the paywall
    func dismissPaywall() {
        shouldShowPaywall = false
    }

    // MARK: - Timeline Restriction Methods

    /// Show paywall due to timeline restriction
    func showPaywallForTimelineRestriction() {
        paywallTrigger = .timelineRestricted
        isTimelineRestricted = true
        shouldShowPaywall = true
        logger.info("Showing paywall for timeline restriction")
    }

    /// Clear timeline restriction (after premium upgrade)
    func clearTimelineRestriction() {
        isTimelineRestricted = false
        logger.info("Timeline restriction cleared")
    }

    /// Reset daily limit (for testing or when day changes)
    func resetDailyLimit() {
        dailyLimitReachedDate = nil
        shouldShowPaywall = false
        saveState()
        logger.info("Daily limit reset")
    }

    /// Reset all limits (called on premium upgrade)
    func resetAllLimits() {
        dailyLimitReachedDate = nil
        isTotalLimitReached = false
        shouldShowPaywall = false
        saveState()
        logger.info("All limits reset (premium upgrade)")
    }

    /// Calculate time until reset (next day at 00:00:01)
    var timeUntilReset: TimeInterval? {
        guard let limitDate = dailyLimitReachedDate else {
            return nil
        }

        let calendar = Calendar.current
        guard let startOfNextDay = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: limitDate)
        )?.addingTimeInterval(1) else { // Add 1 second to get 00:00:01
            return nil
        }

        let now = Date()
        return startOfNextDay.timeIntervalSince(now)
    }

    /// Formatted time until reset
    var timeUntilResetFormatted: String {
        guard let interval = timeUntilReset, interval > 0 else {
            return "Soon"
        }

        let hours = Int(interval) / 3600
        let minutes = (Int(interval) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    // MARK: - Private Methods

    private func checkIfNewDay() {
        guard let limitDate = dailyLimitReachedDate else {
            return
        }

        // If it's a new day, reset the limit
        if !isSameDay(limitDate, Date()) {
            logger.info("New day detected, resetting daily limit")
            resetDailyLimit()
        }
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }

    private func saveState() {
        if let date = dailyLimitReachedDate {
            UserDefaults.standard.set(date, forKey: dailyLimitDateKey)
        } else {
            // Remove the key when date is nil to avoid crash
            UserDefaults.standard.removeObject(forKey: dailyLimitDateKey)
        }
        UserDefaults.standard.set(isTotalLimitReached, forKey: totalLimitReachedKey)
    }

    private func loadState() {
        dailyLimitReachedDate = UserDefaults.standard.object(forKey: dailyLimitDateKey) as? Date
        isTotalLimitReached = UserDefaults.standard.bool(forKey: totalLimitReachedKey)
    }
}
