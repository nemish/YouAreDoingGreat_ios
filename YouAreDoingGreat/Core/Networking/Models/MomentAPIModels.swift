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
    let praiseEnriched: EnrichedPraise?
    let action: String?
    let tags: [String]?
    let isFavorite: Bool?
}

// MARK: - Enriched Praise Models

/// Structured praise with cards and highlights for enhanced UI rendering
struct EnrichedPraise: Codable, Equatable {
    let version: Int
    let cards: [PraiseCard]
}

/// A text card containing a portion of praise with optional highlights
struct PraiseCard: Codable, Equatable, Identifiable {
    var id: String { text }
    let text: String
    let highlights: [PraiseHighlight]
}

/// A highlight span within card text, marking important words/phrases
struct PraiseHighlight: Codable, Equatable {
    let start: Int
    let end: Int
    let type: HighlightType
    let emphasis: EmphasisLevel

    /// Type of highlighted content
    enum HighlightType: String, Codable {
        case positive  // Encouraging words ("amazing", "incredible")
        case action    // User-referencing ("you did", "your effort")
        case number    // Quantified achievements ("3 days", "5th time")
    }

    /// Visual emphasis level
    enum EmphasisLevel: String, Codable {
        case primary   // Bold + accent color (warm gold)
        case secondary // Bold only
    }
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
