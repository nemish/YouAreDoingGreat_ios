import Foundation

// MARK: - App Configuration
// Central configuration for API endpoints, feature flags, and app constants

enum AppConfig {
    // MARK: - API Configuration

    /// Base URL for API endpoints
    static let apiBaseURL: String = {
        #if DEBUG
        // Use local dev server in debug builds if needed
        // return "http://localhost:3000/api/v1"
        return "https://1test1.xyz/api/v1"
        #else
        // Production API URL
        return "https://1test1.xyz/api/v1"
        #endif
    }()

    /// Full URL for moments endpoint
    static var momentsURL: URL? {
        URL(string: "\(apiBaseURL)/moments")
    }

    /// Full URL for timeline endpoint
    static var timelineURL: URL? {
        URL(string: "\(apiBaseURL)/timeline")
    }

    /// Full URL for user stats endpoint
    static var userStatsURL: URL? {
        URL(string: "\(apiBaseURL)/user/stats")
    }

    /// Full URL for user profile endpoint
    static var userProfileURL: URL? {
        URL(string: "\(apiBaseURL)/user/me")
    }

    /// Build URL for a specific moment by ID
    static func momentURL(id: String) -> URL? {
        URL(string: "\(apiBaseURL)/moments/\(id)")
    }

    /// Build URL for moment enrichment endpoint
    static func enrichMomentURL(id: String) -> URL? {
        URL(string: "\(apiBaseURL)/moments/\(id)/enrich")
    }

    // MARK: - API Headers

    /// Header key for user authentication
    static let userIdHeaderKey = "x-user-id"

    /// Placeholder user ID for development (TODO: Replace with actual auth)
    static let developmentUserId = "test-user-id"

    // MARK: - Feature Flags

    /// Enable debug logging
    static let isDebugLoggingEnabled = true

    /// Enable offline mode testing
    static let offlineModeEnabled = false

    // MARK: - Development Mode

    /// Returns true if running in DEBUG build configuration
    static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - App Constants

    /// Maximum number of retries for failed sync operations
    static let maxSyncRetries = 3

    /// Polling interval for AI praise generation (in seconds)
    static let praisePollingInterval: TimeInterval = 2.0

    /// Maximum number of polls for AI praise
    static let maxPraisePolls = 10

    /// Timeout for network requests (in seconds)
    static let networkTimeout: TimeInterval = 30.0
}
