import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "praise")

// MARK: - Praise ViewModel

@MainActor
@Observable
final class PraiseViewModel: PraiseViewModelProtocol {
    // Moment data
    let momentText: String
    let happenedAt: Date
    let timeAgoSeconds: Int?
    let clientId: UUID
    let submittedAt: Date
    let timezone: String

    // Praise state
    var offlinePraise: String
    var aiPraise: String?
    var tags: [String] = []
    var isLoadingAIPraise: Bool = false
    var syncError: String?

    // Animation state
    var showContent: Bool = false
    var showPraise: Bool = false
    var showTags: Bool = false
    var showButton: Bool = false

    // Polling state
    private var pollingTask: Task<Void, Never>?
    private var pollCount: Int = 0
    private let maxPolls: Int = AppConfig.maxPraisePolls
    private let pollInterval: UInt64 = UInt64(AppConfig.praisePollingInterval * 1_000_000_000)

    // Computed properties
    var displayedPraise: String {
        aiPraise ?? offlinePraise
    }

    var isShowingAIPraise: Bool {
        aiPraise != nil
    }

    var timeDisplayText: String {
        guard let seconds = timeAgoSeconds, seconds > 0 else {
            return "Just now"
        }

        if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if seconds < 86400 {
            let hours = seconds / 3600
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = seconds / 86400
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    init(
        momentText: String,
        happenedAt: Date = Date(),
        timeAgoSeconds: Int? = nil,
        offlinePraise: String? = nil,
        clientId: UUID = UUID(),
        submittedAt: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) {
        self.momentText = momentText
        self.happenedAt = happenedAt
        self.timeAgoSeconds = timeAgoSeconds
        self.offlinePraise = offlinePraise ?? Self.randomOfflinePraise()
        self.clientId = clientId
        self.submittedAt = submittedAt
        self.timezone = timezone
    }

    func cancelPolling() {
        pollingTask?.cancel()
    }

    // MARK: - Animation

    func startEntranceAnimation() async {
        // Stagger the animations
        try? await Task.sleep(nanoseconds: 200_000_000)
        withAnimation(.easeOut(duration: 0.4)) {
            showContent = true
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.4)) {
            showPraise = true
        }

        try? await Task.sleep(nanoseconds: 300_000_000)
        withAnimation(.easeOut(duration: 0.3)) {
            showButton = true
        }
    }

    // MARK: - Sync & AI Praise

    func syncMomentAndFetchPraise() async {
        isLoadingAIPraise = true

        do {
            // First, POST the moment to create it on server
            let response = try await createMomentOnServer()

            // Check if praise is already available
            if let praise = response.praise, !praise.isEmpty {
                await updateWithServerResponse(response)
                isLoadingAIPraise = false
                return
            }

            // If no praise yet, start polling
            guard let serverId = response.id else {
                isLoadingAIPraise = false
                return
            }

            await pollForPraise(serverId: serverId)

        } catch let error as MomentError {
            handleMomentError(error)
        } catch {
            logger.error("Failed to sync moment: \(error.localizedDescription)")
            syncError = error.localizedDescription
            isLoadingAIPraise = false
        }
    }

    private func handleMomentError(_ error: MomentError) {
        if error.isDailyLimitError {
            logger.warning("Daily limit reached, showing paywall")
            PaywallService.shared.markDailyLimitReached()
            PaywallService.shared.showPaywall()
        } else {
            logger.error("Moment error: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
        isLoadingAIPraise = false
    }

    private func createMomentOnServer() async throws -> MomentResponse {
        // TODO: Replace with actual API client
        // For now, use URLSession directly

        guard let url = AppConfig.momentsURL else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add anonymous user ID header
        request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

        let body = CreateMomentRequest(
            clientId: clientId.uuidString,
            text: momentText,
            submittedAt: submittedAt,
            tz: timezone,
            timeAgo: timeAgoSeconds
        )

        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MomentError.invalidResponse
        }

        // Handle error responses
        if httpResponse.statusCode == 400 {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                if errorResponse.error.code == .dailyLimitReached {
                    throw MomentError.dailyLimitReached(message: errorResponse.error.message)
                } else {
                    throw MomentError.serverError(message: errorResponse.error.message)
                }
            }
            throw MomentError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error response for other status codes
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw MomentError.serverError(message: errorResponse.error.message)
            }
            throw MomentError.invalidResponse
        }

        do {
            let decoded = try JSONDecoder().decode(CreateMomentResponseWrapper.self, from: data)
            return decoded.item
        } catch {
            throw MomentError.decodingError(error)
        }
    }

    private func pollForPraise(serverId: String) async {
        pollingTask = Task {
            while pollCount < maxPolls && !Task.isCancelled {
                pollCount += 1

                do {
                    try await Task.sleep(nanoseconds: pollInterval)

                    let moment = try await fetchMomentFromServer(serverId: serverId)

                    if let praise = moment.praise, !praise.isEmpty {
                        await updateWithServerResponse(moment)
                        break
                    }

                    logger.debug("Poll \(self.pollCount)/\(self.maxPolls): No praise yet")

                } catch {
                    logger.error("Poll failed: \(error.localizedDescription)")
                    if pollCount >= maxPolls {
                        syncError = "Couldn't fetch extra encouragement this time."
                    }
                }
            }

            await MainActor.run {
                isLoadingAIPraise = false
            }
        }

        await pollingTask?.value
    }

    private func fetchMomentFromServer(serverId: String) async throws -> MomentResponse {
        guard let url = AppConfig.momentURL(id: serverId) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // Add anonymous user ID header
        request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GetMomentResponseWrapper.self, from: data)
        return decoded.item
    }

    private func updateWithServerResponse(_ response: MomentResponse) async {
        await MainActor.run {
            if let praise = response.praise, !praise.isEmpty {
                withAnimation(.easeInOut(duration: 0.35)) {
                    aiPraise = praise
                }
            }

            if let responseTags = response.tags, !responseTags.isEmpty {
                tags = responseTags
                // Animate tags appearing after praise
                Task {
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    withAnimation(.easeOut(duration: 0.3)) {
                        showTags = true
                    }
                }
            }
        }
    }

    // MARK: - Offline Praise Pool

    private static func randomOfflinePraise() -> String {
        let praises = [
            "That's it. Small stuff adds up.",
            "Look at you, doing things.",
            "Every little bit matters.",
            "Nice. You're making moves.",
            "One step at a time. This was one.",
            "Progress isn't always loud.",
            "You showed up. That's the hardest part.",
            "Boom. Done. Next.",
            "Little wins are still wins.",
            "You did something. That's everything.",
            "Not nothing. That's what that was.",
            "Gold star. You've earned it.",
            "Action over perfection. Nailed it.",
            "Small, but mighty.",
            "That counts. Don't let anyone tell you otherwise."
        ]
        return praises.randomElement() ?? praises[0]
    }
}

// MARK: - API Models

private struct CreateMomentRequest: Encodable {
    let clientId: String
    let text: String
    let submittedAt: Date
    let tz: String
    let timeAgo: Int?

    enum CodingKeys: String, CodingKey {
        case clientId, text, submittedAt, tz, timeAgo
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(clientId, forKey: .clientId)
        try container.encode(text, forKey: .text)
        try container.encode(ISO8601DateFormatter().string(from: submittedAt), forKey: .submittedAt)
        try container.encode(tz, forKey: .tz)
        try container.encodeIfPresent(timeAgo, forKey: .timeAgo)
    }
}

private struct CreateMomentResponseWrapper: Decodable {
    let item: MomentResponse
}

private struct GetMomentResponseWrapper: Decodable {
    let item: MomentResponse
}

private struct MomentResponse: Decodable {
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
