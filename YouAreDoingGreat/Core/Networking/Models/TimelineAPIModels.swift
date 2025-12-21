import Foundation

// MARK: - Timeline API Models
// Data transfer objects for timeline/journey feature

/// Response from GET /timeline endpoint
struct TimelineResponseDTO: Decodable {
    let data: [DaySummaryDTO]
    let nextCursor: String?
    let hasNextPage: Bool
    /// Whether the user has reached their timeline limit (true for free users when older data exists)
    /// Defaults to false for backward compatibility with older API versions
    let limitReached: Bool

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor
        case hasNextPage
        case limitReached
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decode([DaySummaryDTO].self, forKey: .data)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        hasNextPage = try container.decode(Bool.self, forKey: .hasNextPage)
        // Default to false if not present for backward compatibility
        limitReached = try container.decodeIfPresent(Bool.self, forKey: .limitReached) ?? false
    }
}

/// Day summary state indicating processing status
enum DaySummaryState: String, Decodable {
    case inProgress = "INPROGRESS"
    case finalised = "FINALISED"
}

/// Day summary with aggregated moment data
struct DaySummaryDTO: Decodable, Identifiable {
    let id: String
    let date: String  // ISO date string
    let text: String?  // AI-generated summary (null if INPROGRESS)
    let tags: [String]
    let momentsCount: Int
    let timesOfDay: [String]  // ["sunrise", "cloud-sun", "sun-medium", "sunset", "moon"]
    let state: DaySummaryState  // INPROGRESS or FINALISED
    let createdAt: String  // ISO datetime string
}
