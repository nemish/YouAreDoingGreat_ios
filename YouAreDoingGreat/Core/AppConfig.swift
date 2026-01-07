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
        return "https://app.you-are-doing-great.com/api/v1"
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

    /// Header key for app token authentication
    static let appTokenHeaderKey = "x-app-token-code"

    /// App token for API access validation
    static let appToken: String = {
        #if DEBUG
        return "6459462c25b4c5112e858c0d2befb150a1964a046db17b92fac3e323648e7a0a"
        #else
        return "U4wmDyJDXYlk8j704oz5ZUeGSIeVr9DL9+FhRYV7mdk="
        #endif
    }()

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

    // MARK: - RevenueCat Configuration

    /// RevenueCat API keys (public keys, safe to commit)
    static let revenueCatAPIKey: String = {
        #if DEBUG
        // Sandbox/test API key for development
        return "test_ETmaetFJRSDFWJdEQZtRkYqodHI"
        #else
        // Production API key
        return "appl_yxHvlKNyslQKbgTsDayWLVtkEjn"
        #endif
    }()

    // MARK: - Legal URLs

    /// Privacy policy URL
    static var privacyPolicyURL: URL? {
        URL(string: "https://you-are-doing-great.com/privacy")
    }

    /// Terms of Use URL
    static var termsOfServiceURL: URL? {
        URL(string: "https://you-are-doing-great.com/terms")
    }

    // MARK: - Subscription Limits

    /// Subscription limit configuration for free and premium tiers
    enum SubscriptionLimits {
        /// Free tier limits
        enum Free {
            /// Maximum moments per day for free users
            static let momentsPerDay = 3
            /// Maximum total moments for free users
            static let totalMoments = 10
            /// Timeline retention period in days
            static let timelineRetentionDays = 14
        }

        /// Premium tier limits
        enum Premium {
            /// Maximum moments per day for premium users
            static let momentsPerDay = 10
            /// Total moments limit (nil = unlimited)
            static let totalMoments: Int? = nil
            /// Timeline retention period (nil = unlimited)
            static let timelineRetentionDays: Int? = nil
        }
    }
}
