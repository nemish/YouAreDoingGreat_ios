import Foundation
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "sparks-progress")

// MARK: - Pending Sparks Toast

struct PendingSparksToast {
    let clientId: UUID
    let sparksAwarded: Int
    let chapterName: String
}

// MARK: - Sparks Progress Service
// Singleton service managing chapter progression state
// Observable from HomeView (progress bar), PraiseView (sparks display), MomentCard (indicators)

@MainActor
@Observable
final class SparksProgressService {
    static let shared = SparksProgressService()

    // MARK: - Chapter Progress State

    var totalSparks: Int = 0
    var chapter: Int = 0
    var chapterName: String = ""
    var nextChapterCost: Int = 50
    var nextChapterThreshold: Int = 50
    var sparksToNextChapter: Int = 50
    var sparksInCurrentChapter: Int = 0
    var isLoaded: Bool = false

    // MARK: - Toast State

    /// Set when praise view is dismissed before sparks are collected
    var pendingSparksToast: PendingSparksToast?

    // MARK: - Dependencies

    private let apiClient: APIClient

    private init(apiClient: APIClient = DefaultAPIClient()) {
        self.apiClient = apiClient
    }

    // MARK: - Computed Properties

    /// Progress fraction (0.0 to 1.0) within current chapter
    var chapterProgress: Double {
        guard nextChapterCost > 0 else { return 0 }
        return Double(sparksInCurrentChapter) / Double(nextChapterCost)
    }

    // MARK: - Public Methods

    /// Update state from POST /moments sparks result
    func updateFromSparksResult(_ result: SparksResult) {
        totalSparks = result.totalSparks
        chapter = result.chapter
        chapterName = result.chapterName
        isLoaded = true
        logger.info("Updated from sparks result: +\(result.awarded) sparks, chapter \(result.chapter) (\(result.chapterName))")

        // SparksResult doesn't include nextChapterThreshold — refresh from server to get updated values
        Task {
            await refresh()
        }
    }

    /// Load state from GET /user/stats response
    func loadFromStats(_ stats: UserStatsDTO) {
        if let sparks = stats.totalSparks {
            totalSparks = sparks
        }
        if let ch = stats.chapter {
            chapter = ch
        }
        if let name = stats.chapterName {
            chapterName = name
        }
        if let cost = stats.nextChapterCost {
            nextChapterCost = cost
        }
        if let threshold = stats.nextChapterThreshold {
            nextChapterThreshold = threshold
        }
        if let remaining = stats.sparksToNextChapter {
            sparksToNextChapter = remaining
        }
        if let inChapter = stats.sparksInCurrentChapter {
            sparksInCurrentChapter = inChapter
        }
        isLoaded = true
    }

    /// Reset all state (called during user journey reset)
    func reset() {
        totalSparks = 0
        chapter = 0
        chapterName = ""
        nextChapterCost = 50
        nextChapterThreshold = 50
        sparksToNextChapter = 50
        sparksInCurrentChapter = 0
        isLoaded = false
        pendingSparksToast = nil
    }

    /// Refresh from server via GET /user/stats
    func refresh() async {
        do {
            let response: UserStatsResponse = try await apiClient.request(
                endpoint: .userStats,
                method: .get,
                body: nil as String?
            )
            loadFromStats(response.item)
            logger.info("Refreshed sparks progress: \(self.totalSparks) total, chapter \(self.chapter)")
        } catch {
            logger.error("Failed to refresh sparks progress: \(error.localizedDescription)")
        }
    }
}
