import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "moment-detail")

// MARK: - Moment Detail View Model
// Adapts an existing Moment to the PraiseViewModelProtocol for display in detail sheet
// Skips entrance animations since the moment already exists

@MainActor
@Observable
final class MomentDetailViewModel: PraiseViewModelProtocol {
    // MARK: - Dependencies

    private let moment: Moment
    private let repository: MomentRepository
    private let onFavoriteToggle: (Moment) async -> Void
    private let onDelete: (String, String?) async -> Void  // Accept String to avoid UUID corruption

    // MARK: - PraiseViewModelProtocol Properties

    var momentText: String {
        moment.text
    }

    var timeAgoSeconds: Int? {
        moment.timeAgo
    }

    var offlinePraise: String {
        moment.offlinePraise
    }

    var aiPraise: String? {
        get { moment.praise }
        set { }  // No-op for detail view
    }

    var tags: [String] {
        get { moment.tags }
        set { }  // No-op for detail view
    }

    var isLoadingAIPraise: Bool {
        get { !moment.isSynced && moment.syncError == nil }
        set { }  // No-op for detail view
    }

    var syncError: String? {
        get { moment.syncError }
        set { }  // No-op for detail view
    }

    // Animation state - all true to skip entrance animations
    var showContent = true
    var showPraise = true
    var showTags = true
    var showButton = true

    var timeDisplayText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: moment.happenedAt, relativeTo: Date())
    }

    var clientId: UUID {
        moment.clientId
    }

    var isNiceButtonDisabled: Bool {
        false  // Detail view never disables button
    }

    // Sync failure state - derived from moment's sync error
    var isLimitBlocked: Bool {
        get {
            guard let error = moment.syncError else { return false }
            return error.contains("limit")
        }
        set { }  // No-op for detail view
    }

    var isSyncFailed: Bool {
        !moment.isSynced && moment.syncError != nil
    }

    // Hug state (maps to moment.isFavorite)
    var isHugged: Bool {
        moment.isFavorite
    }

    // MARK: - Initialization

    init(
        moment: Moment,
        repository: MomentRepository,
        onFavoriteToggle: @escaping (Moment) async -> Void,
        onDelete: @escaping (String, String?) async -> Void  // Accept String to avoid UUID corruption
    ) {
        self.moment = moment
        self.repository = repository
        self.onFavoriteToggle = onFavoriteToggle
        self.onDelete = onDelete

//        logger.info("🔍 MomentDetailViewModel init - clientId: \(moment.clientId), serverId: \(moment.serverId ?? "nil"), isSynced: \(moment.isSynced)")
//        logger.info("🔍 Praise: \(moment.praise?.prefix(50) ?? "nil"), Tags: \(moment.tags)")
    }

    // MARK: - PraiseViewModelProtocol Methods

    func cancelPolling() {
        // No-op - detail view doesn't poll
    }

    func startEntranceAnimation() async {
        // No-op - moment already exists, skip animations
    }

    func syncMomentAndFetchPraise() async {
        // No-op - moment already synced or syncing in background
    }

    func retrySyncMoment() async {
        logger.info("Retry sync requested for moment: \(self.clientId)")

        // Check if still blocked BEFORE clearing state
        if PaywallService.shared.shouldBlockMomentCreation() {
            logger.warning("Still blocked by paywall, showing paywall")
            // Persist error to storage to prevent SyncService retry loops
            moment.syncError = SyncErrorMessages.upgradeRequired
            try? await repository.update(moment)
            PaywallService.shared.showPaywall()
            return
        }

        // Clear the sync error to allow retry
        moment.syncError = nil
        do {
            try await repository.update(moment)
            logger.info("Cleared sync error for moment: \(self.clientId)")

            // Trigger SyncService to pick up this moment
            SyncService.shared.startSyncing(repository: repository)
        } catch {
            logger.error("Failed to clear sync error: \(error.localizedDescription)")
        }
    }

    // MARK: - Action Handlers

    func toggleFavorite() async {
        await onFavoriteToggle(moment)
    }

    func toggleHug() async {
        await toggleFavorite()
    }

    func deleteMoment() async {
        // Capture IDs as Strings BEFORE calling onDelete - SwiftData objects can become invalid
        let clientIdString = moment.clientId.uuidString
        let serverId = moment.serverId
        await onDelete(clientIdString, serverId)
    }
}
