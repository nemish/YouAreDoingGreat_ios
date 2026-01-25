import Foundation

// MARK: - User Profile Response

struct UserResponse: Decodable {
    let item: UserDTO
}

struct UserDTO: Decodable {
    let id: String
    let userId: String
    let status: UserStatus
    let hapticsEnabled: Bool
}

// MARK: - User Status

enum UserStatus: String, Decodable {
    case free
    case premium
}

// MARK: - User Preferences Update

struct UpdateUserPreferencesRequest: Encodable {
    let hapticsEnabled: Bool
}

// MARK: - User Stats Response

struct UserStatsResponse: Decodable {
    let item: UserStatsDTO
}

struct UserStatsDTO: Decodable {
    let totalMoments: Int
    let momentsToday: Int
    let momentsYesterday: Int
    let currentStreak: Int
    let longestStreak: Int
    let lastMomentDate: String?
}

// MARK: - Feedback Request/Response

struct UserFeedbackRequest: Encodable {
    let title: String
    let text: String
}

struct UserFeedbackResponse: Decodable {
    let item: UserFeedback
}

struct UserFeedback: Decodable {
    let id: String
    let title: String
    let text: String
    let createdAt: String?
}
