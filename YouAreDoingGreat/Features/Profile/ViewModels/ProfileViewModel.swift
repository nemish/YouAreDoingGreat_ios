import Foundation
import UIKit
import RevenueCat
import OSLog

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
    var showResetJourneyConfirmation = false
    var isResettingJourney = false

    // Haptic preferences
    private var isSyncingFromServer = false

    var hapticsEnabled: Bool {
        didSet {
            HapticManager.shared.setEnabled(hapticsEnabled)

            // Skip cloud sync when restoring from server to avoid sync loop
            guard !isSyncingFromServer else { return }

            // Sync to backend immediately
            Task {
                do {
                    _ = try await userService.updateHapticPreference(enabled: hapticsEnabled)
                } catch {
                    Logger.app.error("Failed to sync haptic preference: \(error.localizedDescription)")
                }
            }
        }
    }

    var hapticIntensity: Float {
        didSet {
            HapticManager.shared.setIntensity(hapticIntensity)
        }
    }

    // MARK: - Computed Properties

    var maskedUserID: String {
        guard let userId = userProfile?.userId else { return "" }
        guard userId.count > 8 else { return userId }
        let prefix = userId.prefix(4)
        let suffix = userId.suffix(4)
        return "\(prefix)...\(suffix)"
    }

    var isPremium: Bool {
        SubscriptionService.shared.hasActiveSubscription
    }

    var planDescription: String {
        isPremium ? "Enjoy 50 moments per day and advanced analytics"
                  : "Limited to 3 moments per day"
    }

    // MARK: - Initialization

    init(userService: UserService, momentRepository: MomentRepository? = nil) {
        self.userService = userService
        self.momentRepository = momentRepository

        // Initialize haptic preferences from HapticManager
        self.hapticsEnabled = HapticManager.shared.isEnabled
        self.hapticIntensity = HapticManager.shared.intensity
    }

    // MARK: - Public Methods

    func loadProfile() async {
        isLoadingProfile = true
        do {
            async let profile = userService.fetchUserProfile()
            async let stats = userService.fetchUserStats()

            userProfile = try await profile
            userStats = try await stats

            // Restore haptic preference from server (without triggering sync back)
            if let hapticsEnabled = userProfile?.hapticsEnabled {
                isSyncingFromServer = true
                self.hapticsEnabled = hapticsEnabled
                isSyncingFromServer = false
            }
        } catch {
            handleError(error)
        }
        isLoadingProfile = false
    }

    func copyUserID() {
        guard let userId = userProfile?.userId else { return }
        UIPasteboard.general.string = userId
        Task { await HapticManager.shared.play(.gentleTap) }
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
        Task { await HapticManager.shared.play(.gentleTap) }
    }

    /// Resets the entire user journey - clears all data and generates new user ID
    /// - Parameter onComplete: Closure to reset onboarding state (should set hasCompletedOnboarding to false)
    func resetUserJourney(onComplete: @escaping () -> Void) async {
        isResettingJourney = true

        do {
            // 1. Clear all moments from local database
            if let repository = momentRepository {
                try await repository.deleteAll()
            }

            // 2. Reset daily limit
            paywallService.resetDailyLimit()

            // 3. Reset subscription state (for debug purposes)
            #if DEBUG
            SubscriptionService.shared.setHasActiveSubscription(false)
            #endif

            // 4. Generate new user ID
            UserIDProvider.shared.resetUserID()

            // 5. Update RevenueCat with new user ID
            // Must logOut first, then logIn with the new ID
            // logOut alone creates an anonymous $RCAnonymousID which we don't want
            try await Purchases.shared.logOut()
            _ = try await Purchases.shared.logIn(UserIDProvider.shared.userID)

            // 6. Clear cached profile/stats
            userProfile = nil
            userStats = nil

            // 7. Reset first log hint so it shows again
            UserDefaults.standard.removeObject(forKey: "hasCompletedFirstLog")

            // 8. Trigger onboarding reset (this will navigate to WelcomeView)
            onComplete()

            await HapticManager.shared.play(.confidentPress)
        } catch {
            handleError(error)
        }

        isResettingJourney = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        self.error = error.localizedDescription
        showError = true
    }
}
