import Foundation
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "journey")

// MARK: - Journey View Model
// Manages timeline data with cursor-based pagination

@MainActor
@Observable
final class JourneyViewModel {
    // MARK: - Dependencies

    private let apiClient: APIClient

    // MARK: - State

    var items: [DaySummaryDTO] = []
    var isInitialLoading = false
    var isLoadingMore = false
    var isRefreshing = false
    var error: String?
    var showError = false

    // Timeline restriction state (true when limitReached flag is set in API response)
    var isTimelineRestricted = false
    var showTimelineRestrictedPopup = false

    // Pagination
    private var nextCursor: String?
    var canLoadMore: Bool {
        nextCursor != nil
    }

    // MARK: - Initialization

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    // MARK: - Public Methods

    /// Load initial timeline data
    func loadTimeline() async {
        guard !isInitialLoading else { return }

        isInitialLoading = true
        error = nil
        showError = false

        do {
            let response: TimelineResponseDTO = try await apiClient.request(
                endpoint: .timeline(cursor: nil, limit: 20),
                method: .get,
                body: Optional<String>.none
            )

            items = response.data
            nextCursor = response.nextCursor

            // Check if timeline limit is reached (for free users only)
            // Premium users bypass all timeline restrictions
            // Only mark as restricted if there's actually more data being restricted
            // If limitReached is true but hasNextPage is false, the user has their full journey
            if response.limitReached && response.hasNextPage && !SubscriptionService.shared.hasActiveSubscription {
                isTimelineRestricted = true
            }

            logger.info("Loaded \(response.data.count) timeline items, limitReached: \(response.limitReached), hasNextPage: \(response.hasNextPage), isPremium: \(SubscriptionService.shared.hasActiveSubscription)")
        } catch {
            handleError(error)
        }

        isInitialLoading = false
    }

    /// Refresh timeline (pull to refresh)
    func refresh() async {
        guard !isRefreshing else { return }

        isRefreshing = true
        error = nil
        showError = false
        isTimelineRestricted = false
        showTimelineRestrictedPopup = false

        do {
            let response: TimelineResponseDTO = try await apiClient.request(
                endpoint: .timeline(cursor: nil, limit: 20),
                method: .get,
                body: Optional<String>.none
            )

            items = response.data
            nextCursor = response.nextCursor

            // Check if timeline limit is reached (for free users only)
            // Premium users bypass all timeline restrictions
            // Only mark as restricted if there's actually more data being restricted
            // If limitReached is true but hasNextPage is false, the user has their full journey
            if response.limitReached && response.hasNextPage && !SubscriptionService.shared.hasActiveSubscription {
                isTimelineRestricted = true
            }

            logger.info("Refreshed timeline with \(response.data.count) items, limitReached: \(response.limitReached), hasNextPage: \(response.hasNextPage), isPremium: \(SubscriptionService.shared.hasActiveSubscription)")
        } catch {
            handleError(error)
        }

        isRefreshing = false
    }

    /// Load next page of timeline data
    func loadNextPage() async {
        guard !isLoadingMore, let cursor = nextCursor else { return }

        isLoadingMore = true

        do {
            let response: TimelineResponseDTO = try await apiClient.request(
                endpoint: .timeline(cursor: cursor, limit: 20),
                method: .get,
                body: Optional<String>.none
            )

            items.append(contentsOf: response.data)
            nextCursor = response.nextCursor

            // Check if timeline limit is reached (for free users only)
            // Premium users bypass all timeline restrictions
            if response.limitReached && !SubscriptionService.shared.hasActiveSubscription {
                isTimelineRestricted = true
                // Show popup when we've exhausted available data (respects 30-minute cooldown)
                if !response.hasNextPage {
                    if PaywallService.shared.canShowTimelinePopup() {
                        showTimelineRestrictedPopup = true
                        PaywallService.shared.recordTimelinePopupShown()
                        logger.info("Timeline limit reached - showing paywall prompt")
                    } else {
                        logger.info("Timeline limit reached - popup suppressed due to cooldown")
                    }
                    // Stop pagination - we've hit the paywall limit
                    nextCursor = nil
                }
            }

            logger.info("Loaded \(response.data.count) more timeline items, limitReached: \(response.limitReached), isPremium: \(SubscriptionService.shared.hasActiveSubscription)")
        } catch {
            handleError(error)
        }

        isLoadingMore = false
    }

    // MARK: - Private Methods

    private func handleError(_ error: Error) {
        logger.error("Timeline error: \(error.localizedDescription)")
        self.error = error.localizedDescription
        showError = true
    }
}
