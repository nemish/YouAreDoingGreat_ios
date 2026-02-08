import Foundation
import SwiftData

// MARK: - Moment Model
// SwiftData model representing a user moment
// Supports offline-first architecture with local UUID and server ID

@Model
final class Moment {
    // MARK: - Identity

    @Attribute(.unique) var clientId: UUID
    var serverId: String?

    // MARK: - Core Data

    var text: String
    var submittedAt: Date
    var happenedAt: Date
    var timezone: String
    var timeAgo: Int?

    // MARK: - Server-Enriched Data

    var praise: String?
    var praiseEnrichedData: Data?  // JSON storage for SwiftData compatibility
    var action: String?
    var tags: [String]
    var isFavorite: Bool

    // Computed accessor for praiseEnriched (non-persisted)
    @Transient var praiseEnriched: EnrichedPraise? {
        get {
            guard let data = praiseEnrichedData else { return nil }
            return try? JSONDecoder().decode(EnrichedPraise.self, from: data)
        }
        set {
            praiseEnrichedData = try? JSONEncoder().encode(newValue)
        }
    }

    // MARK: - Local-Only Metadata

    var offlinePraise: String
    var isSynced: Bool
    var syncError: String?

    // MARK: - Initialization

    init(
        clientId: UUID = UUID(),
        text: String,
        submittedAt: Date,
        happenedAt: Date,
        timezone: String,
        timeAgo: Int?,
        offlinePraise: String
    ) {
        self.clientId = clientId
        self.text = text
        self.submittedAt = submittedAt
        self.happenedAt = happenedAt
        self.timezone = timezone
        self.timeAgo = timeAgo
        self.offlinePraise = offlinePraise
        self.tags = []
        self.isFavorite = false
        self.isSynced = false
    }

    // MARK: - Computed Properties

    var displayPraise: String {
        praise ?? offlinePraise
    }
}
