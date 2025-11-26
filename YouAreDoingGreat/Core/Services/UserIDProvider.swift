import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "user-id")

// MARK: - User ID Provider
// Manages anonymous user identity across the app
// Generates and persists a UUID on first launch, reuses it thereafter

@Observable
final class UserIDProvider {
    // MARK: - Singleton

    static let shared = UserIDProvider()

    // MARK: - Properties

    private(set) var userID: String

    // MARK: - Initialization

    private init() {
        // Try to load existing user ID from Keychain
        if let existingID = KeychainManager.getUserID() {
            self.userID = existingID
            logger.info("Loaded existing user ID from Keychain")
        } else {
            // Generate new UUID for first launch
            let newID = UUID().uuidString
            self.userID = newID

            // Save to Keychain
            let saved = KeychainManager.saveUserID(newID)
            if saved {
                logger.info("Generated and saved new user ID: \(newID, privacy: .private)")
            } else {
                logger.error("Failed to save user ID to Keychain")
            }
        }
    }

    // MARK: - Public Methods

    /// Updates the user ID (for future authentication migration)
    /// - Parameter newUserID: The new authenticated user ID
    func updateUserID(_ newUserID: String) {
        self.userID = newUserID
        let saved = KeychainManager.saveUserID(newUserID)
        if saved {
            logger.info("Updated user ID to authenticated ID")
        } else {
            logger.error("Failed to update user ID in Keychain")
        }
    }

    /// Resets the user ID (generates a new anonymous ID)
    /// - Note: This will create a fresh anonymous identity
    func resetUserID() {
        let newID = UUID().uuidString
        self.userID = newID
        let saved = KeychainManager.saveUserID(newID)
        if saved {
            logger.info("Reset to new anonymous user ID")
        } else {
            logger.error("Failed to reset user ID in Keychain")
        }
    }
}
