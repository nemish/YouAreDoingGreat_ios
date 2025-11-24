import SwiftUI

// MARK: - Log Moment ViewModel

@MainActor
@Observable
final class LogMomentViewModel {
    // Form state
    var momentText: String = ""
    var timeAgoSeconds: Int? = nil
    var isJustNow: Bool = true

    // UI state
    var isSubmitting: Bool = false
    var showTimePicker: Bool = false

    // Validation
    var isValid: Bool {
        // Text is optional per spec - if left blank we store a placeholder
        true
    }

    // First log pre-fill check
    private let hasCompletedFirstLog: Bool

    init(isFirstLog: Bool = false) {
        self.hasCompletedFirstLog = !isFirstLog

        // Pre-fill for first log per MAIN_SPEC.md
        if isFirstLog {
            momentText = "I installed this app. A tiny step, but it counts."
        }
    }

    // MARK: - Time Selection

    var timeDisplayText: String {
        if isJustNow {
            return "Just now"
        }

        guard let seconds = timeAgoSeconds else {
            return "Just now"
        }

        if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    func setJustNow() {
        isJustNow = true
        timeAgoSeconds = nil
    }

    func setTimeAgo(_ seconds: Int) {
        isJustNow = false
        timeAgoSeconds = seconds
    }

    // MARK: - Submit

    func submit() async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        // Get timezone
        let timezone = TimeZone.current.identifier

        // Calculate happenedAt
        let submittedAt = Date()
        let happenedAt: Date
        if let timeAgo = timeAgoSeconds {
            happenedAt = submittedAt.addingTimeInterval(-Double(timeAgo))
        } else {
            happenedAt = submittedAt
        }

        // Text to save (use placeholder if empty)
        let textToSave = momentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Did something worth noting"
            : momentText.trimmingCharacters(in: .whitespacesAndNewlines)

        // TODO: Save to SwiftData
        // TODO: Select offline praise from JSON pool
        // TODO: Sync to server in background

        // Simulate save for now
        try? await Task.sleep(nanoseconds: 500_000_000)

        return true
    }
}

// MARK: - Time Ago Options

struct TimeAgoOption: Identifiable, Hashable {
    let id = UUID()
    let label: String
    let seconds: Int
}

extension LogMomentViewModel {
    static let timeAgoOptions: [TimeAgoOption] = {
        var options: [TimeAgoOption] = []

        // Minutes: 5, 10, 15, 20, 30, 45
        for minutes in [5, 10, 15, 20, 30, 45] {
            options.append(TimeAgoOption(
                label: "\(minutes) minute\(minutes == 1 ? "" : "s")",
                seconds: minutes * 60
            ))
        }

        // Hours: 1-12
        for hours in 1...12 {
            options.append(TimeAgoOption(
                label: "\(hours) hour\(hours == 1 ? "" : "s")",
                seconds: hours * 3600
            ))
        }

        // Days: 1-3
        for days in 1...3 {
            options.append(TimeAgoOption(
                label: "\(days) day\(days == 1 ? "" : "s")",
                seconds: days * 86400
            ))
        }

        return options
    }()
}
