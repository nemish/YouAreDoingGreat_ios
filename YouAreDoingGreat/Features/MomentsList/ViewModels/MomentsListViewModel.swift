import Foundation
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
    private let repository: MomentRepository
    private var loadTask: Task<Void, Never>?

    // MARK: - State

    var moments: [Moment] = []
    var groupedMoments: [MomentSection] = []

    // MARK: - UI State

    var isInitialLoading: Bool = false
    var isLoadingMore: Bool = false
    var isRefreshing: Bool = false
    var error: String?
    var showError: Bool = false

    // MARK: - Pagination

    var canLoadMore: Bool = false

    // MARK: - Actions

    var selectedMoment: Moment?
    var showActionSheet: Bool = false

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
        } catch {
            handleError(error)
        }

        isInitialLoading = false
    }

    /// Reload moments from local storage (called after background refresh)
    private func reloadFromLocalStorage() async {
        do {
            self.moments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
            )
            self.groupedMoments = groupMomentsByDate(self.moments)
            self.canLoadMore = momentService.hasNextPage
            logger.info("Reloaded \(self.moments.count) moments after background refresh")
        } catch {
            logger.error("Failed to reload moments: \(error.localizedDescription)")
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }

        logger.info("Refreshing moments")
        isRefreshing = true

        do {
            try await momentService.refreshFromServer()

            // Reload all moments from local storage after refresh
            moments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
            )
            groupedMoments = groupMomentsByDate(moments)
            canLoadMore = momentService.hasNextPage
            logger.info("Refresh complete, \(self.moments.count) moments")
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
            logger.info("Loaded \(newMoments.count) more moments")
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

    func deleteMoment(_ moment: Moment) async {
        logger.info("Deleting moment")

        do {
            try await momentService.deleteMoment(moment)
            moments.removeAll { $0.clientId == moment.clientId }
            groupedMoments = groupMomentsByDate(moments)
        } catch {
            handleError(error)
        }
    }

    func showActions(for moment: Moment) {
        selectedMoment = moment
        showActionSheet = true
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
