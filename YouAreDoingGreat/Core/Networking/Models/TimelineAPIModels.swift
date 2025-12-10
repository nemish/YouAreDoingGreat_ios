import Foundation

// MARK: - Timeline API Models
// Data transfer objects for timeline/journey feature

/// Response from GET /timeline endpoint
struct TimelineResponseDTO: Decodable {
    let data: [DaySummaryDTO]
    let nextCursor: String?
    let hasNextPage: Bool

    enum CodingKeys: String, CodingKey {
        case data
        case nextCursor
        case hasNextPage
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
