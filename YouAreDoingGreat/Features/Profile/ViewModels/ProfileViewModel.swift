import Foundation
import UIKit

// MARK: - Profile ViewModel
// State management and business logic for ProfileView

@MainActor
@Observable
final class ProfileViewModel {
    // MARK: - Dependencies

    private let userService: UserService
    private let momentRepository: MomentRepository?
    private let paywallService = PaywallService.shared

    // MARK: - State

    var userProfile: UserDTO?
    var userStats: UserStatsDTO?
    var isLoadingProfile = false
    var error: String?
    var showError = false

    // Feedback form state
    var feedbackTitle = ""
    var feedbackMessage = ""
    var isSubmittingFeedback = false
    var showFeedbackSheet = false
    var feedbackSuccess = false

    // Developer actions
    var showClearDatabaseConfirmation = false
    var isClearingDatabase = false

    // MARK: - Computed Properties

    var maskedUserID: String {
        guard let userId = userProfile?.userId else { return "" }
        guard userId.count > 8 else { return userId }
        let prefix = userId.prefix(4)
        let suffix = userId.suffix(4)
        return "\(prefix)...\(suffix)"
    }

    var isPremium: Bool {
        userProfile?.status == .premium
    }

    var planDescription: String {
        isPremium ? "Enjoy 50 moments per day and advanced analytics"
                  : "Limited to 3 moments per day"
    }

    // MARK: - Initialization

    init(userService: UserService, momentRepository: MomentRepository? = nil) {
        self.userService = userService
        self.momentRepository = momentRepository
    }

    // MARK: - Public Methods

    func loadProfile() async {
        isLoadingProfile = true
        do {
            async let profile = userService.fetchUserProfile()
            async let stats = userService.fetchUserStats()

            userProfile = try await profile
            userStats = try await stats
        } catch {
            handleError(error)
        }
        isLoadingProfile = false
    }

    func copyUserID() {
        guard let userId = userProfile?.userId else { return }
        UIPasteboard.general.string = userId
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func submitFeedback() async {
        guard !feedbackTitle.trimmingCharacters(in: .whitespaces).isEmpty,
              !feedbackMessage.trimmingCharacters(in: .whitespaces).isEmpty else {
            return
        }

        isSubmittingFeedback = true
        do {
            try await userService.submitFeedback(
                title: feedbackTitle,
                text: feedbackMessage
            )
            feedbackSuccess = true
            feedbackTitle = ""
            feedbackMessage = ""

            // Auto-dismiss after success
            Task {
                try? await Task.sleep(for: .seconds(1.5))
                showFeedbackSheet = false
                feedbackSuccess = false
            }
        } catch {
            handleError(error)
        }
        isSubmittingFeedback = false
    }

    func showPaywall() {
        paywallService.shouldShowPaywall = true
    }

    // MARK: - Developer Actions

    func clearLocalDatabase() async {
        guard let repository = momentRepository else { return }

        isClearingDatabase = true
        do {
            try await repository.deleteAll()
            // Success - database cleared
        } catch {
            handleError(error)
        }
        isClearingDatabase = false
    }

    func resetDailyLimit() {
        paywallService.resetDailyLimit()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        self.error = error.localizedDescription
        showError = true
    }
}
