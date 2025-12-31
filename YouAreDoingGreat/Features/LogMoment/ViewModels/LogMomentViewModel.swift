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

    // Placeholder text (randomized on init)
    let placeholderText: String

    // Validation
    var isValid: Bool {
        // Text is optional per spec - if left blank we store a placeholder
        true
    }

    // First log pre-fill check
    private let hasCompletedFirstLog: Bool

    init(isFirstLog: Bool = false) {
        self.hasCompletedFirstLog = !isFirstLog
        self.placeholderText = Self.randomPlaceholder()

        // Pre-fill for first log per MAIN_SPEC.md
        if isFirstLog {
            momentText = "I installed this app. Not a big deal — but not nothing."
        }
    }

    // MARK: - Placeholder Pool

    private static func randomPlaceholder() -> String {
        let placeholders = [
            "Brushed your teeth without rushing",
            "Maybe you just folded your laundry and that was enough",
            "Sent a message you've been putting off",
            "Cooked something decent (or at least edible)",
            "Did some quick stretches before sitting back down",
            "Finally cleared off that one annoying surface",
            "Maybe you just made your bed and called it a win",
            "Organized a tiny corner of your life",
            "Went for a walk instead of scrolling again",
            "Closed a tab you've had open for 3 weeks",
            "Cleaned something that was quietly bothering you",
            "Got dressed even if you had nowhere to go",
            "Maybe you just replied to that one hard email",
            "Moved your body a little — and that's not nothing",
            "Followed through on something small but real",
            "Maybe you took the high road today",
            "Chose to rest instead of forcing productivity",
            "Finally unsubscribed from that thing",
            "Let something go without needing to fix it",
            "Maybe you just showed up and that matters",
            "Said no when you could've said yes and regretted it",
            "Handled a tiny crisis like an adult",
            "Started something instead of planning forever",
            "Looked at your budget without immediately crying",
            "Maybe you cleaned up without telling anyone",
            "Helped someone without needing credit for it",
            "Got through a long call without losing your mind",
            "Maybe you set a timer and did the thing",
            "Faced a task you've been hiding from",
            "Did your thing — and you know which one"
        ]
        return placeholders.randomElement() ?? placeholders[0]
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

        // TODO: Save to SwiftData with the following:
        // - timezone: TimeZone.current.identifier
        // - submittedAt: Date()
        // - happenedAt: submittedAt.addingTimeInterval(-Double(timeAgoSeconds ?? 0))
        // - text: momentText.trimmingCharacters or "Secret"
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
