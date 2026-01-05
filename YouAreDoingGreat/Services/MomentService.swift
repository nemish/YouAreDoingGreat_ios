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

    // Timeline restriction state (true when limitReached flag is set in API response)
    var isLimitReached: Bool = false

    // Filter state
    var isShowingFavoritesOnly: Bool = false

    // MARK: - Initialization

    init(apiClient: APIClient, repository: MomentRepository) {
        self.apiClient = apiClient
        self.repository = repository
    }

    // MARK: - Private Methods

    /// Sync a single moment DTO to local storage
    private func syncMoment(_ dto: MomentDTO) async throws -> Moment {
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
            // Update existing moment with ALL fields from server
            existing.serverId = dto.id
            existing.text = dto.text
            existing.submittedAt = DateFormatters.parseISO8601(dto.submittedAt) ?? existing.submittedAt
            existing.happenedAt = DateFormatters.parseISO8601(dto.happenedAt) ?? existing.happenedAt
            existing.timezone = dto.tz
            existing.timeAgo = dto.timeAgo
            existing.praise = dto.praise
            existing.action = dto.action
            existing.tags = dto.tags ?? []
            existing.isFavorite = dto.isFavorite ?? false
            // Only mark as synced if enrichment is complete (has praise)
            existing.isSynced = dto.praise != nil && !(dto.praise?.isEmpty ?? true)
            try await repository.update(existing)
            moment = existing
        } else {
            // Create new moment from server data
            let clientId = UUID(uuidString: dto.clientId ?? "") ?? UUID()

            let newMoment = Moment(
                clientId: clientId,
                text: dto.text,
                submittedAt: DateFormatters.parseISO8601(dto.submittedAt) ?? Date(),
                happenedAt: DateFormatters.parseISO8601(dto.happenedAt) ?? Date(),
                timezone: dto.tz,
                timeAgo: dto.timeAgo,
                offlinePraise: "" // Server data doesn't need offline praise
            )

            newMoment.serverId = dto.id
            newMoment.praise = dto.praise
            newMoment.action = dto.action
            newMoment.tags = dto.tags ?? []
            newMoment.isFavorite = dto.isFavorite ?? false
            // Only mark as synced if enrichment is complete (has praise)
            newMoment.isSynced = dto.praise != nil && !(dto.praise?.isEmpty ?? true)
            try await repository.save(newMoment)
            moment = newMoment
        }

        return moment
    }

    // MARK: - Public Methods

    /// Load initial moments (local first, then sync from server)
    func loadInitialMoments(onBackgroundRefreshComplete: (() -> Void)? = nil) async throws -> [Moment] {
        // 1. Load from SwiftData immediately (offline-first)
        var localMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        // Apply favorites filter if active
        if isShowingFavoritesOnly {
            localMoments = localMoments.filter { $0.isFavorite }
        }

        logger.info("Loaded \(localMoments.count) moments from local storage, favoritesOnly: \(self.isShowingFavoritesOnly)")

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
        logger.info("Refreshing moments from server, favoritesOnly: \(self.isShowingFavoritesOnly)")

        let response: PaginatedMomentsResponse = try await apiClient.request(
            endpoint: .moments(cursor: nil, limit: 50, isFavorite: isShowingFavoritesOnly ? true : nil),
            method: .get,
            body: nil as String?
        )

        // Save or update all fetched moments
        for dto in response.data {
            _ = try await syncMoment(dto)
        }

        // Update pagination state
        nextCursor = response.nextCursor
        hasNextPage = response.hasNextPage
        isLimitReached = response.limitReached

        logger.info("Refreshed \(response.data.count) moments, hasNextPage: \(response.hasNextPage), limitReached: \(response.limitReached)")
    }

    /// Load next page of moments
    func loadNextPage() async throws -> [Moment] {
        guard let cursor = nextCursor, hasNextPage else {
            logger.debug("No more pages to load")
            return []
        }

        logger.info("Loading next page with cursor: \(cursor), favoritesOnly: \(self.isShowingFavoritesOnly)")

        let response: PaginatedMomentsResponse = try await apiClient.request(
            endpoint: .moments(cursor: cursor, limit: 20, isFavorite: isShowingFavoritesOnly ? true : nil),
            method: .get,
            body: nil as String?
        )

        var moments: [Moment] = []

        for dto in response.data {
            let moment = try await syncMoment(dto)
            moments.append(moment)
        }

        // Update pagination state
        nextCursor = response.nextCursor
        hasNextPage = response.hasNextPage
        isLimitReached = response.limitReached

        logger.info("Loaded \(moments.count) moments from next page, limitReached: \(response.limitReached)")

        return moments
    }

    /// Toggle favorites filter mode
    func setFavoritesFilter(_ enabled: Bool) {
        isShowingFavoritesOnly = enabled
        // Reset pagination when filter changes
        nextCursor = nil
        hasNextPage = false
        isLimitReached = false
        logger.info("Favorites filter set to: \(enabled)")
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
            let _: EmptyResponse = try await apiClient.request(
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
