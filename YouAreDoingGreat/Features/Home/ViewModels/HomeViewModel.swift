import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "home-view")

// MARK: - Home ViewModel
// Manages state for HomeView, including user stats loading

@MainActor
@Observable
final class HomeViewModel {
    private let userService: UserService

    // MARK: - State

    var userStats: UserStatsDTO?
    var isLoadingStats = false
    var statsError: String?
    var statsWhisper: String = ""

    // MARK: - Constants

    private let whispers = [
        "Every number here is a story you told yourself.",
        "Tiny things. Big difference.",
        "The fact you're tracking this means you care.",
        "Little moments. Real effort. Honest wins.",
        "No one else needed to see it — just you."
    ]

    // MARK: - Initialization

    init(userService: UserService) {
        self.userService = userService
    }

    // MARK: - Public Methods

    func loadStats() async {
        isLoadingStats = true
        defer { isLoadingStats = false }

        do {
            userStats = try await userService.fetchUserStats()
            statsWhisper = whispers.randomElement() ?? whispers[0]
        } catch {
            statsError = error.localizedDescription
            logger.error("Failed to load user stats: \(error.localizedDescription)")
        }
    }

    func refreshStats() async {
        // Force refresh - clear error and reload
        statsError = nil
        await loadStats()
    }
}
