import Foundation
import SwiftUI
import SwiftData
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "moments-list-vm")

// MARK: - Moments List ViewModel
// Manages state and coordinates actions for the moments list screen

@MainActor
@Observable
final class MomentsListViewModel {
    // MARK: - Dependencies

    private let momentService: MomentService
    let repository: MomentRepository
    private var loadTask: Task<Void, Never>?
    private var syncMonitorTask: Task<Void, Never>?

    // MARK: - State

    var moments: [Moment] = []
    var groupedMoments: [MomentSection] = []

    // MARK: - UI State

    var isInitialLoading: Bool = false
    var isLoadingMore: Bool = false
    var isRefreshing: Bool = false
    var error: String?
    var showError: Bool = false

    // Timeline restriction state (true when limitReached flag is set in API response)
    var isTimelineRestricted: Bool = false
    var showTimelineRestrictedPopup: Bool = false

    // Favorites filter (read from MomentService for consistency)
    var isShowingFavoritesOnly: Bool {
        momentService.isShowingFavoritesOnly
    }

    // MARK: - Pagination

    var canLoadMore: Bool = false

    // MARK: - Actions

    // Detail sheet state
    var selectedMomentForDetail: Moment?
    var showMomentDetail: Bool = false

    // MARK: - Initialization

    init(momentService: MomentService, repository: MomentRepository) {
        self.momentService = momentService
        self.repository = repository
    }

    // MARK: - Public Methods

    func loadMoments() async {
        guard !isInitialLoading else { return }

        logger.info("Loading moments")
        isInitialLoading = true

        do {
            moments = try await momentService.loadInitialMoments { [weak self] in
                Task { @MainActor in
                    await self?.reloadFromLocalStorage()
                }
            }
            groupedMoments = groupMomentsByDate(moments)
            canLoadMore = momentService.hasNextPage
            logger.info("Loaded \(self.moments.count) moments")

            // Start background sync service
            SyncService.shared.startSyncing(repository: repository)

            // Start monitoring for sync updates
            startSyncMonitoring()
        } catch {
            handleError(error)
        }

        isInitialLoading = false
    }

    /// Start monitoring for unsynced moments that get synced in the background
    private func startSyncMonitoring() {
        // Cancel existing monitor if any
        syncMonitorTask?.cancel()

        // Filter to only count syncable moments (exclude limit-blocked ones)
        let initialUnsyncedCount = moments.filter { !$0.isSynced && !isLimitBlocked($0) }.count

        guard initialUnsyncedCount > 0 else {
            logger.info("No syncable unsynced moments, skipping sync monitoring")
            return
        }

        logger.info("Starting sync monitoring with \(initialUnsyncedCount) syncable unsynced moments")

        syncMonitorTask = Task { @MainActor in
            var previousUnsyncedCount = initialUnsyncedCount

            while !Task.isCancelled {
                // Wait 2 seconds between checks
                try? await Task.sleep(nanoseconds: 2_000_000_000)

                // Fetch current unsynced moments from storage
                if let unsyncedMoments = try? await repository.fetchUnsyncedMoments() {
                    // Filter to only count syncable moments (exclude limit-blocked ones)
                    let syncableMoments = unsyncedMoments.filter { !isLimitBlocked($0) }
                    let currentUnsyncedCount = syncableMoments.count

                    logger.debug("Sync monitor check: \(currentUnsyncedCount) syncable unsynced moments (was \(previousUnsyncedCount))")

                    // If the count changed, it means something got synced
                    if currentUnsyncedCount != previousUnsyncedCount {
                        logger.info("Sync status changed: \(previousUnsyncedCount) -> \(currentUnsyncedCount) syncable unsynced moments - reloading")
                        await reloadFromLocalStorage()
                        previousUnsyncedCount = currentUnsyncedCount
                    }

                    // Stop monitoring if there are no more syncable unsynced moments
                    if currentUnsyncedCount == 0 {
                        logger.info("All syncable moments synced, stopping monitor")
                        break
                    }
                }
            }
        }
    }

    /// Check if a moment is blocked by limits (won't be retried)
    private func isLimitBlocked(_ moment: Moment) -> Bool {
        guard let syncError = moment.syncError else { return false }
        return SyncErrorMessages.isLimitError(syncError)
    }

    /// Stop monitoring for sync updates
    func stopSyncMonitoring() {
        syncMonitorTask?.cancel()
        syncMonitorTask = nil
    }

    /// Reload moments from local storage (called after background refresh)
    private func reloadFromLocalStorage() async {
        do {
            var loadedMoments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
            )

            // Filter by favorites if filter is active
            if isShowingFavoritesOnly {
                loadedMoments = loadedMoments.filter { $0.isFavorite }
            }

            self.moments = loadedMoments
            self.groupedMoments = groupMomentsByDate(self.moments)
            self.canLoadMore = momentService.hasNextPage

            // Update timeline restriction state after background refresh
            // Only mark as restricted if there's actually more data being restricted
            if momentService.isLimitReached && momentService.hasNextPage {
                isTimelineRestricted = true
            }

            logger.info("Reloaded \(self.moments.count) moments after background refresh, favoritesOnly: \(self.isShowingFavoritesOnly), limitReached: \(self.momentService.isLimitReached), hasNextPage: \(self.momentService.hasNextPage)")
        } catch {
            logger.error("Failed to reload moments: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }

        logger.info("Refreshing moments, favoritesOnly: \(self.isShowingFavoritesOnly)")
        isRefreshing = true
        isTimelineRestricted = false
        showTimelineRestrictedPopup = false

        do {
            try await momentService.refreshFromServer()

            // Reload all moments from local storage after refresh
            var loadedMoments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
            )

            // Filter by favorites if filter is active
            if isShowingFavoritesOnly {
                loadedMoments = loadedMoments.filter { $0.isFavorite }
            }

            moments = loadedMoments
            groupedMoments = groupMomentsByDate(moments)
            canLoadMore = momentService.hasNextPage

            // Check if timeline limit is reached (for free users)
            // Only mark as restricted if there's actually more data being restricted
            // If limitReached is true but hasNextPage is false, the user has their full data
            if momentService.isLimitReached && momentService.hasNextPage {
                isTimelineRestricted = true
            }

            logger.info("Refresh complete, \(self.moments.count) moments, favoritesOnly: \(self.isShowingFavoritesOnly), limitReached: \(self.momentService.isLimitReached), hasNextPage: \(self.momentService.hasNextPage)")

            // Restart sync service to pick up any unsynced moments
            SyncService.shared.startSyncing(repository: repository)
            startSyncMonitoring()
        } catch {
            handleError(error)
        }

        isRefreshing = false
    }

    func loadNextPage() async {
        guard canLoadMore, !isLoadingMore else { return }

        logger.info("Loading next page")
        isLoadingMore = true

        do {
            let newMoments = try await momentService.loadNextPage()
            moments.append(contentsOf: newMoments)
            groupedMoments = groupMomentsByDate(moments)
            canLoadMore = momentService.hasNextPage

            // Check if timeline limit is reached (for free users)
            // Only mark as restricted if there's actually more data being restricted
            if momentService.isLimitReached && momentService.hasNextPage {
                isTimelineRestricted = true
            } else if momentService.isLimitReached && !momentService.hasNextPage {
                // Hit the limit boundary - show restriction UI
                isTimelineRestricted = true
                showTimelineRestrictedPopup = true
                canLoadMore = false
                logger.info("Timeline limit reached - showing paywall prompt")
            }

            logger.info("Loaded \(newMoments.count) more moments, limitReached: \(self.momentService.isLimitReached), hasNextPage: \(self.momentService.hasNextPage)")
        } catch {
            handleError(error)
        }

        isLoadingMore = false
    }

    func toggleFavorite(_ moment: Moment) async {
        logger.info("Toggling favorite for moment")

        do {
            try await momentService.toggleFavorite(moment)
        } catch {
            handleError(error)
        }
    }

    func deleteMomentByIds(clientId: UUID, serverId: String?) async {
        logger.info("Deleting moment by IDs: \(clientId)")

        do {
            try await momentService.deleteMoment(clientId: clientId, serverId: serverId)

            // Animate the removal with fade + shrink
            withAnimation(.easeOut(duration: 0.45)) {
                moments.removeAll { $0.clientId == clientId }
                groupedMoments = groupMomentsByDate(moments)
            }

            // Show deletion confirmation toast
            ToastService.shared.showDeleted()
        } catch {
            handleError(error)
        }
    }

    func deleteMoment(_ moment: Moment) async {
        // Capture IDs immediately to avoid accessing invalid SwiftData object
        let clientId = moment.clientId
        let serverId = moment.serverId
        await deleteMomentByIds(clientId: clientId, serverId: serverId)
    }

    /// Toggle favorites-only filter mode
    func toggleFavoritesFilter() async {
        let newFilterState = !isShowingFavoritesOnly
        logger.info("Toggling favorites filter: \(newFilterState)")

        // Toggle filter state in service (resets pagination)
        momentService.setFavoritesFilter(newFilterState)

        // Load filtered data from local storage first (immediate, no network)
        do {
            var loadedMoments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
            )

            // Apply filter
            if newFilterState {
                loadedMoments = loadedMoments.filter { $0.isFavorite }
            }

            // Animate transition to new data
            withAnimation(.easeOut(duration: 0.25)) {
                moments = loadedMoments
                groupedMoments = groupMomentsByDate(moments)
            }
        } catch {
            logger.error("Failed to load filtered moments: \(error.localizedDescription)")
        }

        // Refresh from server in background (non-blocking)
        Task {
            await refresh()
        }
    }

    func showDetail(for moment: Moment) {
        selectedMomentForDetail = moment
        showMomentDetail = true
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        logger.error("Error: \(error.localizedDescription)")
        self.error = error.localizedDescription
        showError = true
    }

    private func groupMomentsByDate(_ moments: [Moment]) -> [MomentSection] {
        let calendar = Calendar.current

        // Group moments by start of day
        let grouped = Dictionary(grouping: moments) { moment in
            calendar.startOfDay(for: moment.happenedAt)
        }

        // Convert to sections and sort
        return grouped.map { date, moments in
            MomentSection(
                date: date,
                moments: moments.sorted { $0.happenedAt > $1.happenedAt }
            )
        }
        .sorted { $0.date > $1.date }
    }
}

// MARK: - Moment Section

struct MomentSection: Identifiable {
    let id = UUID()
    let date: Date
    let moments: [Moment]

    var displayDate: String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}
