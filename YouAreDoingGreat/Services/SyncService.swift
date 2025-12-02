import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "sync-service")

// MARK: - Sync Service
// Background service that syncs unsynced moments with the server
// Lives independently of view lifecycle

@MainActor
@Observable
final class SyncService {
    static let shared = SyncService()

    private var syncTask: Task<Void, Never>?
    private let pollInterval: UInt64 = 3_000_000_000 // 3 seconds
    private let maxPollsPerMoment: Int = 10

    private init() {}

    // MARK: - Public Methods

    /// Start monitoring and syncing unsynced moments
    func startSyncing(repository: MomentRepository) {
        // Cancel existing sync task if any
        syncTask?.cancel()

        logger.info("🔄 Starting sync service")

        syncTask = Task { @MainActor in
            while !Task.isCancelled {
                do {
                    // Fetch all unsynced moments
                    let unsyncedMoments = try await repository.fetchUnsyncedMoments()

                    if !unsyncedMoments.isEmpty {
                        logger.info("🔄 Found \(unsyncedMoments.count) unsynced moment(s)")

                        // Try to sync each unsynced moment
                        for moment in unsyncedMoments {
                            if Task.isCancelled { break }
                            await syncMoment(moment, repository: repository)
                        }
                    } else {
                        // No unsynced moments - stop the service
                        logger.info("✅ All moments synced - stopping sync service")
                        break
                    }

                    // Wait before next check
                    try await Task.sleep(nanoseconds: pollInterval)

                } catch is CancellationError {
                    logger.info("🔄 Sync service cancelled")
                    break
                } catch {
                    logger.error("❌ Sync service error: \(error.localizedDescription)")
                    // Continue on error
                    try? await Task.sleep(nanoseconds: pollInterval)
                }
            }

            logger.info("🔄 Sync service stopped")
        }
    }

    /// Stop syncing
    func stopSyncing() {
        logger.info("🔄 Stopping sync service")
        syncTask?.cancel()
        syncTask = nil
    }

    // MARK: - Private Methods

    /// Sync a single moment with the server
    private func syncMoment(_ moment: Moment, repository: MomentRepository) async {
        // Check if moment has serverId
        if let serverId = moment.serverId {
            // Moment exists on server, just fetch latest state
            await fetchAndUpdateMoment(moment, serverId: serverId, repository: repository)

            // If still not enriched after fetch, request enrichment
            if moment.praise == nil || moment.praise?.isEmpty == true {
                await requestEnrichmentForMoment(moment, serverId: serverId, repository: repository)
            }
        } else {
            // No serverId - need to check if moment exists on server by clientId
            // If exists, save serverId and sync
            // If not exists, create it
            await syncMomentByClientId(moment, repository: repository)
        }
    }

    /// Sync moment by clientId (when we don't have serverId yet)
    private func syncMomentByClientId(_ moment: Moment, repository: MomentRepository) async {
        logger.info("🔍 Fetching moment by clientId \(moment.clientId.uuidString)")

        do {
            // Try to fetch moment from server by clientId
            let response = try await fetchMomentByClientId(clientId: moment.clientId.uuidString)

            // Moment exists on server! Save the serverId
            if let serverId = response.id {
                moment.serverId = serverId
                logger.info("✅ Found moment on server with serverId \(serverId)")
            }

            // Check if moment has complete data (praise, tags, action)
            if let praise = response.praise, !praise.isEmpty {
                // Moment has all data - sync it
                moment.praise = praise
                moment.action = response.action
                moment.tags = response.tags ?? []
                moment.isSynced = true
                try await repository.update(moment)
                logger.info("✅ Moment \(moment.clientId.uuidString) synced from server!")
            } else {
                // Moment exists but no praise yet - keep it unsynced, will poll again
                try await repository.update(moment)
                logger.debug("⏳ Moment exists on server but no praise yet")
            }

        } catch let error as URLError where error.code == .badServerResponse {
            // Moment doesn't exist on server - create it
            logger.info("📤 Moment not found on server, creating...")
            await createMomentOnServer(moment, repository: repository)
        } catch {
            logger.error("❌ Failed to fetch moment by clientId: \(error.localizedDescription)")
        }
    }

    /// Create moment on server (for moments that don't exist on server yet)
    private func createMomentOnServer(_ moment: Moment, repository: MomentRepository) async {
        do {
            // POST moment to server
            guard let url = AppConfig.momentsURL else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

            let body = CreateMomentRequest(
                clientId: moment.clientId.uuidString,
                text: moment.text,
                submittedAt: moment.submittedAt,
                tz: moment.timezone,
                timeAgo: moment.timeAgo
            )

            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(CreateMomentResponseWrapper.self, from: data)
            let momentResponse = decoded.item

            // Save serverId
            if let serverId = momentResponse.id {
                moment.serverId = serverId
                logger.info("✅ Created moment on server with serverId \(serverId)")
            }

            // Update with any data from server (including praise if already generated)
            if let praise = momentResponse.praise, !praise.isEmpty {
                moment.praise = praise
                moment.action = momentResponse.action
                moment.tags = momentResponse.tags ?? []
                moment.isSynced = true
                logger.info("✅ Moment \(moment.clientId.uuidString) already has praise - synced!")
            } else {
                // No praise yet, will be picked up in next sync cycle
                logger.debug("⏳ Moment created on server, waiting for praise...")
            }

            try await repository.update(moment)

        } catch {
            logger.error("❌ Failed to create moment on server: \(error.localizedDescription)")
        }
    }

    /// Request enrichment for a moment (Phase 2: POST /moments/:id/enrich)
    private func requestEnrichmentForMoment(
        _ moment: Moment,
        serverId: String,
        repository: MomentRepository
    ) async {
        logger.info("🎨 Requesting enrichment for moment \(serverId)")

        do {
            guard let url = AppConfig.enrichMomentURL(id: serverId) else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }

            // Handle 409 Conflict (enrichment already in progress) - this is OK, just wait
            if httpResponse.statusCode == 409 {
                logger.debug("⏳ Enrichment already in progress for \(serverId), will check again later")
                return
            }

            // Log other errors for debugging
            if !(200...299).contains(httpResponse.statusCode) {
                let responseBody = String(data: data, encoding: .utf8) ?? "Unable to decode response"
                logger.error("❌ Enrichment failed with status \(httpResponse.statusCode): \(responseBody)")
                throw URLError(.badServerResponse)
            }

            let decoded = try JSONDecoder().decode(GetMomentResponseWrapper.self, from: data)
            let enriched = decoded.item

            // Update moment if enriched
            if let praise = enriched.praise, !praise.isEmpty {
                logger.info("📝 Updating moment with praise: \(praise.prefix(50))...")
                logger.info("📝 Tags: \(enriched.tags ?? [])")
                logger.info("📝 Action: \(enriched.action ?? "nil")")

                moment.praise = praise
                moment.action = enriched.action
                moment.tags = enriched.tags ?? []
                moment.isSynced = true
                try await repository.update(moment)

                logger.info("✅ Moment \(serverId) enriched in background - praise: \(moment.praise?.prefix(30) ?? "nil"), tags: \(moment.tags)")
            } else {
                logger.debug("⏳ Enrichment requested but not ready yet for \(serverId)")
            }

        } catch {
            logger.error("❌ Failed to request enrichment: \(error)")
        }
    }

    /// Fetch and update existing moment from server
    private func fetchAndUpdateMoment(_ moment: Moment, serverId: String, repository: MomentRepository) async {
        logger.debug("🔄 Syncing moment with serverId \(serverId)")

        do {
            // Fetch latest state from server
            let response = try await fetchMomentFromServer(serverId: serverId)

            // Check if enriched
            if let praise = response.praise, !praise.isEmpty {
                moment.praise = praise
                moment.action = response.action
                moment.tags = response.tags ?? []
                moment.isSynced = true
                try await repository.update(moment)
                logger.info("✅ Updated moment \(serverId) - now synced!")
            } else {
                // Not enriched yet - request enrichment
                logger.debug("⏳ Moment \(serverId) - no praise yet, requesting enrichment")
                await requestEnrichmentForMoment(moment, serverId: serverId, repository: repository)
            }

        } catch {
            logger.error("❌ Failed to sync moment \(serverId): \(error)")
        }
    }

    /// Fetch moment from server by serverId
    private func fetchMomentFromServer(serverId: String) async throws -> MomentResponse {
        guard let url = AppConfig.momentURL(id: serverId) else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GetMomentResponseWrapper.self, from: data)
        return decoded.item
    }

    /// Fetch moment from server by clientId
    /// Expected API endpoint: GET /api/v1/moments/by-client-id/{clientId}
    /// Returns 404 if moment doesn't exist on server
    private func fetchMomentByClientId(clientId: String) async throws -> MomentResponse {
        guard let baseURL = URL(string: AppConfig.apiBaseURL) else {
            throw URLError(.badURL)
        }

        // Expected endpoint: GET /api/v1/moments/by-client-id/{clientId}
        let url = baseURL.appendingPathComponent("moments/by-client-id/\(clientId)")

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: AppConfig.userIdHeaderKey)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        // 404 means moment doesn't exist on server yet
        if httpResponse.statusCode == 404 {
            throw URLError(.badServerResponse)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(GetMomentResponseWrapper.self, from: data)
        return decoded.item
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
