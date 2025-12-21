import Foundation

// MARK: - API Response Models

struct PaginatedMomentsResponse: Decodable {
    let data: [MomentDTO]
    let nextCursor: String?
    let hasNextPage: Bool
    /// Whether the user has reached their timeline limit (true for free users when older data exists)
    let limitReached: Bool
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

struct DeleteMomentResponse: Decodable {
    let success: Bool
}

// MARK: - API Request Models

struct UpdateMomentRequest: Encodable {
    let isFavorite: Bool
}
