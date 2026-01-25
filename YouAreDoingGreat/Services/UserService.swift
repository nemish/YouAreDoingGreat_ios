import Foundation

// MARK: - User Service
// Handles all user-related API calls (profile, stats, feedback)

@MainActor
@Observable
final class UserService {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    func fetchUserProfile() async throws -> UserDTO {
        let response: UserResponse = try await apiClient.request(
            endpoint: .userProfile,
            method: .get,
            body: nil as String?
        )
        return response.item
    }

    func fetchUserStats() async throws -> UserStatsDTO {
        let response: UserStatsResponse = try await apiClient.request(
            endpoint: .userStats,
            method: .get,
            body: nil as String?
        )
        return response.item
    }

    func submitFeedback(title: String, text: String) async throws {
        let _: UserFeedbackResponse = try await apiClient.request(
            endpoint: .submitFeedback,
            method: .post,
            body: UserFeedbackRequest(title: title, text: text)
        )
    }

    func updateHapticPreference(enabled: Bool) async throws -> UserDTO {
        let response: UserResponse = try await apiClient.request(
            endpoint: .userProfile,
            method: .patch,
            body: UpdateUserPreferencesRequest(hapticsEnabled: enabled)
        )
        return response.item
    }
}
