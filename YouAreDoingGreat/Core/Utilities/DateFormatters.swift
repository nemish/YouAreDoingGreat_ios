import Foundation

// MARK: - Date Formatters
// Centralized date parsing and formatting utilities

enum DateFormatters {
    /// ISO8601 formatter for parsing API responses
    /// Handles fractional seconds (e.g., "2025-11-27T22:00:00.000Z")
    static let iso8601: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// ISO8601 formatter without fractional seconds
    /// For formatting dates to send to API
    static let iso8601Basic: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    /// Parses ISO8601 date string from API
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Returns: Parsed Date or nil if parsing fails
    static func parseISO8601(_ dateString: String) -> Date? {
        // Try with fractional seconds first
        if let date = iso8601.date(from: dateString) {
            return date
        }
        // Fallback to basic format
        return iso8601Basic.date(from: dateString)
    }

    /// Formats a date component (day or month) from an ISO8601 string using UTC timezone
    /// This is important for timeline dates that represent calendar days, not specific moments
    /// - Parameters:
    ///   - dateString: ISO8601 formatted date string
    ///   - format: Date format string (e.g., "d" for day, "MMM" for month)
    /// - Returns: Formatted string or empty string if parsing fails
    static func formatUTCComponent(_ dateString: String, format: String) -> String {
        guard let date = parseISO8601(dateString) else {
            return ""
        }

        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: date)
    }

    /// Gets the calendar day from an ISO8601 string, ignoring time component
    /// Useful for day-based comparisons in timeline
    /// - Parameter dateString: ISO8601 formatted date string
    /// - Returns: Date representing start of day in UTC, or nil if parsing fails
    static func calendarDay(from dateString: String) -> Date? {
        guard let date = parseISO8601(dateString) else {
            return nil
        }

        var calendar = Calendar.current
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar.startOfDay(for: date)
    }
}
