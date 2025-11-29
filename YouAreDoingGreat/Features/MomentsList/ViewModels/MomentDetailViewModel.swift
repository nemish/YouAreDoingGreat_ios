import Foundation

// MARK: - Moment Detail View Model
// Adapts an existing Moment to the PraiseViewModelProtocol for display in detail sheet
// Skips entrance animations since the moment already exists

@MainActor
@Observable
final class MomentDetailViewModel: PraiseViewModelProtocol {
    // MARK: - Dependencies

    private let moment: Moment
    private let onFavoriteToggle: (Moment) async -> Void
    private let onDelete: (Moment) async -> Void

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

    // MARK: - Initialization

    init(
        moment: Moment,
        onFavoriteToggle: @escaping (Moment) async -> Void,
        onDelete: @escaping (Moment) async -> Void
    ) {
        self.moment = moment
        self.onFavoriteToggle = onFavoriteToggle
        self.onDelete = onDelete
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

    // MARK: - Action Handlers

    func toggleFavorite() async {
        await onFavoriteToggle(moment)
    }

    func deleteMoment() async {
        await onDelete(moment)
    }
}
