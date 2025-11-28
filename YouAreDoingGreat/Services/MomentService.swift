import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "moment-service")

// MARK: - Moment Service
// Coordinates moment data between local storage and remote API
// Implements offline-first strategy with background sync

@MainActor
@Observable
final class MomentService {
    // MARK: - Dependencies

    private let apiClient: APIClient
    private let repository: MomentRepository

    // MARK: - Pagination State

    var nextCursor: String?
    var hasNextPage: Bool = false

    // MARK: - Initialization

    init(apiClient: APIClient, repository: MomentRepository) {
        self.apiClient = apiClient
        self.repository = repository
    }

    // MARK: - Public Methods

    /// Load initial moments (local first, then sync from server)
    func loadInitialMoments(onBackgroundRefreshComplete: (() -> Void)? = nil) async throws -> [Moment] {
        // 1. Load from SwiftData immediately (offline-first)
        let localMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        logger.info("Loaded \(localMoments.count) moments from local storage")

        // 2. Fetch from server in background (non-blocking)
        Task { @MainActor in
            do {
                try await refreshFromServer()
                logger.info("Background refresh completed")
                onBackgroundRefreshComplete?()
            } catch {
                logger.error("Background refresh failed: \(error.localizedDescription)")
            }
        }

        return localMoments
    }

    /// Refresh from server (pull-to-refresh)
    func refreshFromServer() async throws {
        logger.info("Refreshing moments from server")

        let response: PaginatedMomentsResponse = try await apiClient.request(
            endpoint: .moments(cursor: nil, limit: 50),
            method: .get,
            body: nil as String?
        )

        // Save or update all fetched moments
        for dto in response.data {
            // Check if moment already exists by serverId or clientId
            var existingMoment: Moment?

            if let serverId = dto.id {
                existingMoment = try await repository.fetch(serverId: serverId)
            }

            if existingMoment == nil, let clientIdString = dto.clientId, let clientId = UUID(uuidString: clientIdString) {
                existingMoment = try await repository.fetch(clientId: clientId)
            }

            if let moment = existingMoment {
                // Update existing moment
                moment.serverId = dto.id
                moment.praise = dto.praise
                moment.action = dto.action
                moment.tags = dto.tags ?? []
                moment.isFavorite = dto.isFavorite ?? false
                moment.isSynced = true
                try await repository.update(moment)
                logger.debug("Updated existing moment with serverId: \(dto.id ?? "nil")")
            } else {
                // Create new moment
                let moment = dto.toMoment()
                moment.serverId = dto.id
                moment.praise = dto.praise
                moment.action = dto.action
                moment.tags = dto.tags ?? []
                moment.isFavorite = dto.isFavorite ?? false
                moment.isSynced = true
                try await repository.save(moment)
                logger.debug("Saved new moment with serverId: \(dto.id ?? "nil")")
            }
        }

        // Update pagination state
        nextCursor = response.nextCursor
        hasNextPage = response.hasNextPage

        logger.info("Refreshed \(response.data.count) moments, hasNextPage: \(response.hasNextPage)")
    }

    /// Load next page of moments
    func loadNextPage() async throws -> [Moment] {
        guard let cursor = nextCursor, hasNextPage else {
            logger.debug("No more pages to load")
            return []
        }

        logger.info("Loading next page with cursor: \(cursor)")

        let response: PaginatedMomentsResponse = try await apiClient.request(
            endpoint: .moments(cursor: cursor, limit: 20),
            method: .get,
            body: nil as String?
        )

        var moments: [Moment] = []

        for dto in response.data {
            // Check if moment already exists by serverId or clientId
            var existingMoment: Moment?

            if let serverId = dto.id {
                existingMoment = try await repository.fetch(serverId: serverId)
            }

            if existingMoment == nil, let clientIdString = dto.clientId, let clientId = UUID(uuidString: clientIdString) {
                existingMoment = try await repository.fetch(clientId: clientId)
            }

            let moment: Moment
            if let existing = existingMoment {
                // Update existing moment
                existing.serverId = dto.id
                existing.praise = dto.praise
                existing.action = dto.action
                existing.tags = dto.tags ?? []
                existing.isFavorite = dto.isFavorite ?? false
                existing.isSynced = true
                try await repository.update(existing)
                moment = existing
                logger.debug("Updated existing moment with serverId: \(dto.id ?? "nil")")
            } else {
                // Create new moment
                let newMoment = dto.toMoment()
                newMoment.serverId = dto.id
                newMoment.praise = dto.praise
                newMoment.action = dto.action
                newMoment.tags = dto.tags ?? []
                newMoment.isFavorite = dto.isFavorite ?? false
                newMoment.isSynced = true
                try await repository.save(newMoment)
                moment = newMoment
                logger.debug("Saved new moment with serverId: \(dto.id ?? "nil")")
            }

            moments.append(moment)
        }

        // Update pagination state
        nextCursor = response.nextCursor
        hasNextPage = response.hasNextPage

        logger.info("Loaded \(moments.count) moments from next page")

        return moments
    }

    /// Toggle favorite status
    func toggleFavorite(_ moment: Moment) async throws {
        logger.info("Toggling favorite for moment: \(moment.clientId.uuidString)")

        // Optimistic update: Update local state immediately
        moment.isFavorite.toggle()
        try await repository.update(moment)

        // Sync to server if moment has been synced before
        if let serverId = moment.serverId {
            let _: UpdateMomentResponse = try await apiClient.request(
                endpoint: .updateMoment(id: serverId),
                method: .put,
                body: UpdateMomentRequest(isFavorite: moment.isFavorite)
            )
            logger.info("Favorite status synced to server")
        } else {
            logger.warning("Moment not yet synced to server, favorite state is local only")
        }
    }

    /// Delete moment
    func deleteMoment(_ moment: Moment) async throws {
        logger.info("Deleting moment: \(moment.clientId.uuidString)")

        // Delete from local storage
        try await repository.delete(moment)

        // Delete from server if moment has been synced
        if let serverId = moment.serverId {
            let _: DeleteMomentResponse = try await apiClient.request(
                endpoint: .deleteMoment(id: serverId),
                method: .delete,
                body: nil as String?
            )
            logger.info("Moment deleted from server")
        } else {
            logger.warning("Moment not yet synced to server, deleted locally only")
        }
    }
}
