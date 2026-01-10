import Foundation
@testable import YouAreDoingGreat

// MARK: - Moment Fixtures
// Provides factory methods for creating test moments with sensible defaults

enum MomentFixtures {
    /// Create a test moment with default or custom values
    static func moment(
        clientId: UUID = UUID(),
        text: String = "Test moment",
        submittedAt: Date = Date(),
        happenedAt: Date = Date(),
        timezone: String = "UTC",
        timeAgo: Int? = nil,
        offlinePraise: String = "Nice — that counts!",
        serverId: String? = nil,
        praise: String? = nil,
        action: String? = nil,
        tags: [String] = [],
        isFavorite: Bool = false,
        isSynced: Bool = false,
        syncError: String? = nil
    ) -> Moment {
        let moment = Moment(
            clientId: clientId,
            text: text,
            submittedAt: submittedAt,
            happenedAt: happenedAt,
            timezone: timezone,
            timeAgo: timeAgo,
            offlinePraise: offlinePraise
        )

        moment.serverId = serverId
        moment.praise = praise
        moment.action = action
        moment.tags = tags
        moment.isFavorite = isFavorite
        moment.isSynced = isSynced
        moment.syncError = syncError

        return moment
    }

    /// Create a synced moment (has server ID and AI praise)
    static func syncedMoment(
        text: String = "Shipped a feature",
        praise: String = "Wow, that's amazing! You're making real progress."
    ) -> Moment {
        moment(
            text: text,
            serverId: UUID().uuidString,
            praise: praise,
            isSynced: true
        )
    }

    /// Create an unsynced moment (no server ID, no AI praise)
    static func unsyncedMoment(
        text: String = "Fixed a bug",
        offlinePraise: String = "Nice — that counts!"
    ) -> Moment {
        moment(
            text: text,
            offlinePraise: offlinePraise,
            isSynced: false
        )
    }

    /// Create a favorite moment
    static func favoriteMoment(
        text: String = "Had a great day",
        praise: String = "That's wonderful! Keep it up."
    ) -> Moment {
        moment(
            text: text,
            serverId: UUID().uuidString,
            praise: praise,
            isFavorite: true,
            isSynced: true
        )
    }

    /// Create a moment with sync error
    static func momentWithSyncError(
        text: String = "Failed sync",
        syncError: String = "Network error"
    ) -> Moment {
        moment(
            text: text,
            isSynced: false,
            syncError: syncError
        )
    }
}

// MARK: - API Model Fixtures

/// Encodable version of MomentDTO for testing
struct EncodableMomentDTO: Codable {
    let id: String?
    let clientId: String?
    let text: String
    let submittedAt: String
    let happenedAt: String
    let tz: String
    let timeAgo: Int?
    let praise: String?
    let action: String?
    let tags: [String]?
    let isFavorite: Bool?
}

/// Encodable version of PaginatedMomentsResponse for testing
struct EncodablePaginatedResponse: Codable {
    let data: [EncodableMomentDTO]
    let nextCursor: String?
    let hasNextPage: Bool
    let limitReached: Bool
}

extension MomentFixtures {
    /// Create an encodable MomentDTO for API response mocking
    static func momentDTO(
        id: String? = UUID().uuidString,
        clientId: String? = UUID().uuidString,
        text: String = "Test moment",
        submittedAt: String = DateFormatters.iso8601Basic.string(from: Date()),
        happenedAt: String = DateFormatters.iso8601Basic.string(from: Date()),
        tz: String = "UTC",
        timeAgo: Int? = nil,
        praise: String? = "Great job!",
        action: String? = "Keep going",
        tags: [String]? = ["achievement"],
        isFavorite: Bool? = false
    ) -> EncodableMomentDTO {
        return EncodableMomentDTO(
            id: id,
            clientId: clientId,
            text: text,
            submittedAt: submittedAt,
            happenedAt: happenedAt,
            tz: tz,
            timeAgo: timeAgo,
            praise: praise,
            action: action,
            tags: tags,
            isFavorite: isFavorite
        )
    }

    /// Create a paginated moments response for API mocking
    static func paginatedResponse(
        moments: [EncodableMomentDTO],
        nextCursor: String? = nil,
        hasNextPage: Bool = false,
        limitReached: Bool = false
    ) -> EncodablePaginatedResponse {
        return EncodablePaginatedResponse(
            data: moments,
            nextCursor: nextCursor,
            hasNextPage: hasNextPage,
            limitReached: limitReached
        )
    }
}
