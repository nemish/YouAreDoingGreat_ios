import Foundation

// MARK: - API Response Models

struct PaginatedMomentsResponse: Decodable {
    let data: [MomentDTO]
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
        data = try container.decode([MomentDTO].self, forKey: .data)
        nextCursor = try container.decodeIfPresent(String.self, forKey: .nextCursor)
        hasNextPage = try container.decode(Bool.self, forKey: .hasNextPage)
        // Default to false if not present for backward compatibility
        limitReached = try container.decodeIfPresent(Bool.self, forKey: .limitReached) ?? false
    }
}

struct MomentDTO: Decodable {
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

struct UpdateMomentResponse: Decodable {
    let message: String
}

/// Empty response that accepts any JSON structure (including empty object {})
/// Used for DELETE endpoints that may return empty or minimal responses
struct EmptyResponse: Decodable {
    init() {}

    init(from decoder: Decoder) throws {
        // Accept any structure - we don't care about the content
    }
}

// MARK: - API Request Models

struct UpdateMomentRequest: Encodable {
    let isFavorite: Bool
}
