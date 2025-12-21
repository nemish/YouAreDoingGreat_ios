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
    private let apiClient: APIClient

    private init(apiClient: APIClient = DefaultAPIClient()) {
        self.apiClient = apiClient
    }

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

                    // Filter out limit-blocked moments (they won't be retried)
                    let syncableMoments = unsyncedMoments.filter { moment in
                        guard let syncError = moment.syncError else { return true }
                        return !isLimitError(syncError)
                    }

                    if !syncableMoments.isEmpty {
                        logger.info("🔄 Found \(syncableMoments.count) syncable moment(s) (\(unsyncedMoments.count - syncableMoments.count) blocked by limits)")

                        // Try to sync each syncable moment
                        for moment in syncableMoments {
                            if Task.isCancelled { break }
                            await syncMoment(moment, repository: repository)
                        }
                    } else if unsyncedMoments.isEmpty {
                        // No unsynced moments at all - stop the service
                        logger.info("✅ All moments synced - stopping sync service")
                        break
                    } else {
                        // All unsynced moments are limit-blocked - stop the service
                        logger.info("⏹️ All unsynced moments are blocked by limits - stopping sync service")
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
        // Skip moments that are blocked by limits (no point retrying)
        if let syncError = moment.syncError, isLimitError(syncError) {
            logger.debug("⏭️ Skipping moment \(moment.clientId.uuidString) - blocked by limit")
            return
        }

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
            let response: GetMomentResponseWrapper = try await apiClient.request(
                endpoint: .momentByClientId(clientId: moment.clientId.uuidString),
                method: .get,
                body: EmptyBody?.none
            )
            let momentResponse = response.item

            // Moment exists on server! Save the serverId
            if let serverId = momentResponse.id {
                moment.serverId = serverId
                logger.info("✅ Found moment on server with serverId \(serverId)")
            }

            // Check if moment has complete data (praise, tags, action)
            if let praise = momentResponse.praise, !praise.isEmpty {
                // Moment has all data - sync it
                moment.praise = praise
                moment.action = momentResponse.action
                moment.tags = momentResponse.tags ?? []
                moment.isSynced = true
                try await repository.update(moment)
                logger.info("✅ Moment \(moment.clientId.uuidString) synced from server!")
            } else {
                // Moment exists but no praise yet - keep it unsynced, will poll again
                try await repository.update(moment)
                logger.debug("⏳ Moment exists on server but no praise yet")
            }

        } catch let error as MomentError where error.isNotFoundError {
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
            let body = CreateMomentRequest(
                clientId: moment.clientId.uuidString,
                text: moment.text,
                submittedAt: moment.submittedAt,
                tz: moment.timezone,
                timeAgo: moment.timeAgo
            )

            let response: CreateMomentResponseWrapper = try await apiClient.request(
                endpoint: .createMoment,
                method: .post,
                body: body
            )
            let momentResponse = response.item

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

        } catch let error as MomentError {
            // Check if it's a limit error
            if error.isLimitError {
                // Limit reached - mark moment with error and stop retrying
                logger.warning("⚠️ Limit reached for moment \(moment.clientId.uuidString) - stopping sync attempts")
                moment.syncError = error.isDailyLimitError
                    ? SyncErrorMessages.dailyLimitReached
                    : SyncErrorMessages.totalLimitReached
                try? await repository.update(moment)

                // Show paywall
                if error.isDailyLimitError {
                    PaywallService.shared.markDailyLimitReached()
                } else {
                    PaywallService.shared.markTotalLimitReached()
                }
                PaywallService.shared.showPaywall()
            } else {
                logger.error("❌ Moment error: \(error.localizedDescription)")
            }
        } catch {
            logger.error("❌ Failed to create moment on server: \(error.localizedDescription)")
        }
    }

    /// Check if a sync error message indicates a limit error
    private func isLimitError(_ errorMessage: String) -> Bool {
        SyncErrorMessages.isLimitError(errorMessage)
    }

    /// Request enrichment for a moment (Phase 2: POST /moments/:id/enrich)
    private func requestEnrichmentForMoment(
        _ moment: Moment,
        serverId: String,
        repository: MomentRepository
    ) async {
        logger.info("🎨 Requesting enrichment for moment \(serverId)")

        do {
            let response: EnrichMomentResponseWrapper = try await apiClient.request(
                endpoint: .enrichMoment(id: serverId),
                method: .post,
                body: EmptyBody?.none
            )
            let enriched = response.item

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

        } catch let error as MomentError where error.isEnrichmentInProgressError {
            // 409 Conflict - enrichment already in progress, this is OK
            logger.debug("⏳ Enrichment already in progress for \(serverId), will check again later")
        } catch {
            logger.error("❌ Failed to request enrichment: \(error)")
        }
    }

    /// Fetch and update existing moment from server
    private func fetchAndUpdateMoment(_ moment: Moment, serverId: String, repository: MomentRepository) async {
        logger.debug("🔄 Syncing moment with serverId \(serverId)")

        do {
            // Fetch latest state from server
            let response: GetMomentResponseWrapper = try await apiClient.request(
                endpoint: .moment(id: serverId),
                method: .get,
                body: EmptyBody?.none
            )
            let momentResponse = response.item

            // Check if enriched
            if let praise = momentResponse.praise, !praise.isEmpty {
                moment.praise = praise
                moment.action = momentResponse.action
                moment.tags = momentResponse.tags ?? []
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
}

// MARK: - API Models

struct CreateMomentRequest: Encodable {
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

struct CreateMomentResponseWrapper: Decodable {
    let item: MomentResponse
}

struct GetMomentResponseWrapper: Decodable {
    let item: MomentResponse
}

struct EnrichMomentResponseWrapper: Decodable {
    let item: MomentResponse
}

struct MomentResponse: Decodable {
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

/// Empty body for requests that don't need a body
struct EmptyBody: Encodable {}

// MARK: - MomentError Extensions

extension MomentError {
    var isNotFoundError: Bool {
        if case .serverError(let message) = self {
            return message.lowercased().contains("not found")
        }
        return false
    }

    var isEnrichmentInProgressError: Bool {
        if case .serverError(let message) = self {
            return message.lowercased().contains("in progress") || message.lowercased().contains("conflict")
        }
        return false
    }
}
