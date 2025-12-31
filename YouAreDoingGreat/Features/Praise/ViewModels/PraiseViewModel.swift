import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.youaredoinggreat", category: "praise")

// MARK: - Sync Error Messages
// Centralized error messages for consistent limit detection

enum SyncErrorMessages {
    static let dailyLimitReached = "Daily limit reached"
    static let totalLimitReached = "Total limit reached"
    static let upgradeRequired = "Limit reached"  // Generic for retry blocked state

    /// Check if an error message indicates a limit error
    static func isLimitError(_ errorMessage: String) -> Bool {
        let lowercased = errorMessage.lowercased()
        return lowercased.contains("limit")
    }
}

// MARK: - Praise ViewModel

@MainActor
@Observable
final class PraiseViewModel: PraiseViewModelProtocol {
    // Dependencies
    private let repository: MomentRepository
    private let apiClient: APIClient

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

    // Two-phase sync state
    var isCreatingMoment: Bool = false      // Phase 1: POST /moments
    var isEnrichingMoment: Bool = false     // Phase 2: POST /enrich

    // Sync failure state (blocked by limit) - check both local state AND moment's syncError
    var isLimitBlocked: Bool {
        get {
            // Check local moment's syncError first (set by SyncService)
            if let moment = localMoment, let syncError = moment.syncError {
                let lowercased = syncError.lowercased()
                if lowercased.contains("limit") {
                    return true
                }
            }
            return _isLimitBlocked
        }
        set {
            _isLimitBlocked = newValue
        }
    }
    private var _isLimitBlocked: Bool = false

    // Animation state
    var showContent: Bool = false
    var showPraise: Bool = false
    var showTags: Bool = false
    var showButton: Bool = false

    // Polling state
    private nonisolated(unsafe) var pollingTask: Task<Void, Never>?
    private var pollCount: Int = 0
    private let maxPolls: Int = AppConfig.maxPraisePolls
    private let pollInterval: UInt64 = UInt64(AppConfig.praisePollingInterval * 1_000_000_000)

    // Save task (for cancellation in deinit)
    private nonisolated(unsafe) var saveTask: Task<Void, Never>?

    // Local moment reference
    private var localMoment: Moment?

    // Computed properties
    var displayedPraise: String {
        aiPraise ?? offlinePraise
    }

    var isShowingAIPraise: Bool {
        aiPraise != nil
    }

    var isNiceButtonDisabled: Bool {
        isCreatingMoment  // Only disabled during Phase 1
    }

    var isSyncFailed: Bool {
        // Sync failed if limit blocked or has sync error (but not still loading)
        (isLimitBlocked || syncError != nil) && !isLoadingAIPraise
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
        repository: MomentRepository,
        apiClient: APIClient = DefaultAPIClient(),
        momentText: String,
        happenedAt: Date = Date(),
        timeAgoSeconds: Int? = nil,
        offlinePraise: String? = nil,
        clientId: UUID = UUID(),
        submittedAt: Date = Date(),
        timezone: String = TimeZone.current.identifier
    ) {
        self.repository = repository
        self.apiClient = apiClient
        self.momentText = momentText
        self.happenedAt = happenedAt
        self.timeAgoSeconds = timeAgoSeconds
        self.offlinePraise = offlinePraise ?? Self.randomOfflinePraise()
        self.clientId = clientId
        self.submittedAt = submittedAt
        self.timezone = timezone

        // Save moment to local storage immediately
        saveTask = Task {
            await saveLocalMoment()
        }
    }

    deinit {
        saveTask?.cancel()
        pollingTask?.cancel()
    }

    private func saveLocalMoment() async {
        let moment = Moment(
            clientId: clientId,
            text: momentText,
            submittedAt: submittedAt,
            happenedAt: happenedAt,
            timezone: timezone,
            timeAgo: timeAgoSeconds,
            offlinePraise: offlinePraise
        )
        moment.isSynced = false  // Mark as not synced yet

        do {
            try await repository.save(moment)
            localMoment = moment
            logger.info("Saved moment locally: \(self.clientId.uuidString)")
        } catch {
            logger.error("Failed to save moment locally: \(error.localizedDescription)")
        }
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
        // Phase 1: Create moment on server (BLOCKING - button disabled)
        isCreatingMoment = true
        isLoadingAIPraise = true

        do {
            let response = try await createMomentOnServer()

            // Save serverId immediately for background sync
            if let serverId = response.id, let moment = localMoment {
                moment.serverId = serverId
                try? await repository.update(moment)
                logger.info("Saved serverId \(serverId)")
            }

            // Phase 1 complete - enable Nice button
            isCreatingMoment = false

            // Check if enrichment already complete
            if let praise = response.praise, !praise.isEmpty {
                await updateWithServerResponse(response)
                isLoadingAIPraise = false
                return
            }

            // Phase 2: Request enrichment (NON-BLOCKING - button enabled)
            guard let serverId = response.id else {
                isLoadingAIPraise = false
                return
            }

            await requestEnrichment(serverId: serverId)

        } catch let error as MomentError {
            isCreatingMoment = false
            isLoadingAIPraise = false
            handleMomentError(error)
        } catch is CancellationError {
            // Task was cancelled (user dismissed view) - this is expected, don't log as error
            isCreatingMoment = false
            logger.debug("Sync task cancelled by user")
            isLoadingAIPraise = false
        } catch {
            isCreatingMoment = false
            isLoadingAIPraise = false
            logger.error("Failed to create moment: \(error)")
            syncError = error.localizedDescription
        }
    }

    private func requestEnrichment(serverId: String) async {
        isEnrichingMoment = true

        do {
            // POST to enrichment endpoint
            let enriched = try await enrichMomentOnServer(serverId: serverId)

            // Check if enrichment complete
            if let praise = enriched.praise, !praise.isEmpty {
                await updateWithServerResponse(enriched)
                isEnrichingMoment = false
                isLoadingAIPraise = false
                return
            }

            // Not ready yet - start polling
            await pollForEnrichment(serverId: serverId)

        } catch let error as MomentError {
            isEnrichingMoment = false
            isLoadingAIPraise = false
            handleMomentError(error)
        } catch is CancellationError {
            // Task was cancelled (user dismissed) - this is expected
            isEnrichingMoment = false
            isLoadingAIPraise = false
            logger.debug("Enrichment cancelled by user")
        } catch let error as URLError where error.code == .cancelled {
            // URLSession task was cancelled - this is expected when user dismisses
            isEnrichingMoment = false
            isLoadingAIPraise = false
            logger.debug("Enrichment request cancelled")
        } catch {
            isEnrichingMoment = false
            isLoadingAIPraise = false
            logger.error("Failed to request enrichment: \(error)")
            syncError = "Couldn't fetch extra encouragement this time."
        }
    }

    private func handleMomentError(_ error: MomentError) {
        if error.isDailyLimitError {
            logger.warning("Daily limit reached, showing paywall")
            _isLimitBlocked = true
            syncError = SyncErrorMessages.dailyLimitReached
            PaywallService.shared.markDailyLimitReached()
            PaywallService.shared.showPaywall()
            markLocalMomentSyncFailed(error: SyncErrorMessages.dailyLimitReached)
        } else if error.isTotalLimitError {
            logger.warning("Total limit reached, showing paywall")
            _isLimitBlocked = true
            syncError = SyncErrorMessages.totalLimitReached
            PaywallService.shared.markTotalLimitReached()
            PaywallService.shared.showPaywall()
            markLocalMomentSyncFailed(error: SyncErrorMessages.totalLimitReached)
        } else {
            logger.error("Moment error: \(error.localizedDescription)")
            syncError = error.localizedDescription
        }
        isLoadingAIPraise = false
    }

    private func markLocalMomentSyncFailed(error: String) {
        guard let moment = localMoment else { return }
        moment.isSynced = false
        moment.syncError = error
        Task {
            try? await repository.update(moment)
        }
    }

    /// Retry syncing moment (called after user upgrades or limit resets)
    func retrySyncMoment() async {
        // Check if we should still be blocked BEFORE clearing state
        if PaywallService.shared.shouldBlockMomentCreation() {
            logger.warning("Still blocked, showing paywall")
            _isLimitBlocked = true
            syncError = SyncErrorMessages.upgradeRequired
            // Persist to storage to prevent SyncService retry loops
            if let moment = localMoment {
                moment.syncError = SyncErrorMessages.upgradeRequired
                try? await repository.update(moment)
            }
            PaywallService.shared.showPaywall()
            return
        }

        // Reset error state
        _isLimitBlocked = false
        syncError = nil

        // Clear moment's sync error
        if let moment = localMoment {
            moment.syncError = nil
            try? await repository.update(moment)
        }

        // Retry the sync
        await syncMomentAndFetchPraise()
    }

    private func createMomentOnServer() async throws -> MomentResponse {
        let body = CreateMomentRequest(
            clientId: clientId.uuidString,
            text: momentText,
            submittedAt: submittedAt,
            tz: timezone,
            timeAgo: timeAgoSeconds
        )

        let response: CreateMomentResponseWrapper = try await apiClient.request(
            endpoint: .createMoment,
            method: .post,
            body: body
        )
        return response.item
    }

    private func enrichMomentOnServer(serverId: String) async throws -> MomentResponse {
        do {
            let response: EnrichMomentResponseWrapper = try await apiClient.request(
                endpoint: .enrichMoment(id: serverId),
                method: .post,
                body: EmptyBody?.none
            )
            return response.item
        } catch let error as MomentError where error.isEnrichmentInProgressError {
            // Handle 409 Conflict (enrichment already in progress) gracefully
            logger.debug("⏳ Enrichment already in progress, will continue polling")
            // Return empty response, polling will continue
            return MomentResponse(
                id: serverId,
                clientId: nil,
                text: "",
                submittedAt: "",
                happenedAt: "",
                tz: "",
                timeAgo: nil,
                praise: nil,
                action: nil,
                tags: nil,
                isFavorite: nil
            )
        }
    }

    private func pollForEnrichment(serverId: String) async {
        pollingTask = Task {
            while self.pollCount < self.maxPolls && !Task.isCancelled {
                self.pollCount += 1

                do {
                    try await Task.sleep(nanoseconds: self.pollInterval)

                    // Poll enrichment endpoint (idempotent)
                    let enriched = try await self.enrichMomentOnServer(serverId: serverId)

                    if let praise = enriched.praise, !praise.isEmpty {
                        await self.updateWithServerResponse(enriched)
                        break
                    }

                    logger.debug("Poll \(self.pollCount)/\(self.maxPolls): No praise yet")

                } catch is CancellationError {
                    logger.debug("Enrichment polling cancelled")
                    break
                } catch {
                    logger.error("Enrichment poll failed: \(error)")
                    if self.pollCount >= self.maxPolls {
                        self.syncError = "Couldn't fetch extra encouragement this time."
                    }
                }
            }

            await MainActor.run {
                self.isEnrichingMoment = false
                self.isLoadingAIPraise = false
            }
        }

        await pollingTask?.value
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

        // Update local moment with server data
        guard let moment = localMoment else { return }

        moment.serverId = response.id
        moment.praise = response.praise
        moment.action = response.action
        moment.tags = response.tags ?? []
        moment.isSynced = true

        do {
            try await repository.update(moment)
            logger.info("Updated local moment with server data: \(self.clientId.uuidString)")
        } catch {
            logger.error("Failed to update local moment: \(error.localizedDescription)")
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
