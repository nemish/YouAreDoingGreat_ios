import SwiftUI

// MARK: - Praise ViewModel

@MainActor
@Observable
final class PraiseViewModel {
    // Moment data
    let momentText: String
    let happenedAt: Date
    let timeAgoSeconds: Int?

    // Praise state
    var offlinePraise: String
    var aiPraise: String?
    var isLoadingAIPraise: Bool = false

    // Animation state
    var showContent: Bool = false
    var showPraise: Bool = false
    var showButton: Bool = false

    // Computed properties
    var displayedPraise: String {
        aiPraise ?? offlinePraise
    }

    var isShowingAIPraise: Bool {
        aiPraise != nil
    }

    var timeDisplayText: String {
        guard let seconds = timeAgoSeconds, seconds > 0 else {
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

    init(
        momentText: String,
        happenedAt: Date = Date(),
        timeAgoSeconds: Int? = nil,
        offlinePraise: String? = nil
    ) {
        self.momentText = momentText
        self.happenedAt = happenedAt
        self.timeAgoSeconds = timeAgoSeconds
        self.offlinePraise = offlinePraise ?? Self.randomOfflinePraise()
    }

    // MARK: - Animation

    func startEntranceAnimation() async {
        // Stagger the animations
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.easeOut(duration: 0.4)) {
            showContent = true
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.4)) {
            showPraise = true
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.3)) {
            showButton = true
        }
    }

    // MARK: - AI Praise

    func fetchAIPraise() async {
        isLoadingAIPraise = true
        defer { isLoadingAIPraise = false }

        // TODO: Fetch AI praise from server
        // For now, simulate a delay and keep offline praise
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        // When AI praise arrives, animate the transition
        // withAnimation(.easeInOut(duration: 0.35)) {
        //     aiPraise = fetchedPraise
        // }
    }

    // MARK: - Offline Praise Pool

    private static func randomOfflinePraise() -> String {
        let praises = [
            "That's it. Small stuff adds up.",
            "Look at you, doing things.",
            "Every little bit matters.",
            "Nice. You're making moves.",
            "One step at a time. This was one.",
            "Progress isn't always loud.",
            "You showed up. That's the hardest part.",
            "Boom. Done. Next.",
            "Little wins are still wins.",
            "You did something. That's everything.",
            "Not nothing. That's what that was.",
            "Gold star. You've earned it.",
            "Action over perfection. Nailed it.",
            "Small, but mighty.",
            "That counts. Don't let anyone tell you otherwise."
        ]
        return praises.randomElement() ?? praises[0]
    }
}
