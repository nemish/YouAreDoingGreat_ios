import Foundation

// MARK: - API Response Models

struct PaginatedMomentsResponse: Decodable {
    let data: [MomentDTO]
    let nextCursor: String?
    let hasNextPage: Bool
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

    // MARK: - Conversion to Domain Model

    func toMoment() -> Moment {
        let dateFormatter = ISO8601DateFormatter()

        return Moment(
            clientId: UUID(uuidString: clientId ?? "") ?? UUID(),
            text: text,
            submittedAt: dateFormatter.date(from: submittedAt) ?? Date(),
            happenedAt: dateFormatter.date(from: happenedAt) ?? Date(),
            timezone: tz,
            timeAgo: timeAgo,
            offlinePraise: "" // Will be populated by service layer if needed
        )
    }
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
