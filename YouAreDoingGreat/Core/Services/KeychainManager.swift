import Foundation
import Security

// MARK: - Keychain Manager
// Secure storage utility for persisting sensitive data like user IDs

final class KeychainManager {
    // MARK: - Constants

    private static let service = "ee.required.you-are-doing-great"
    private static let userIDKey = "anonymous_user_id"

    // MARK: - User ID Methods

    /// Retrieves the stored user ID from Keychain
    /// - Returns: The UUID string if found, nil otherwise
    static func getUserID() -> String? {
        guard let data = read(key: userIDKey) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Saves the user ID to Keychain
    /// - Parameter userID: The UUID string to save
    /// - Returns: True if save succeeded, false otherwise
    @discardableResult
    static func saveUserID(_ userID: String) -> Bool {
        guard let data = userID.data(using: .utf8) else { return false }
        return save(key: userIDKey, data: data)
    }

    /// Deletes the stored user ID from Keychain
    /// - Returns: True if delete succeeded, false otherwise
    @discardableResult
    static func deleteUserID() -> Bool {
        return delete(key: userIDKey)
    }

    // MARK: - Generic Keychain Operations

    /// Saves data to Keychain
    private static func save(key: String, data: Data) -> Bool {
        // Check if item already exists
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        // Add new item
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Reads data from Keychain
    private static func read(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else { return nil }
        return result as? Data
    }

    /// Deletes data from Keychain
    private static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }
}
