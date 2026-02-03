import Foundation
import SwiftUI
import SwiftData

@MainActor
@Observable
final class GalaxyViewModel {
    // MARK: - Dependencies
    private let repository: MomentRepository
    private let coordinateEngine: GalaxyCoordinateEngine

    // MARK: - State
    var moments: [Moment] = []
    var selectedMoment: Moment?
    var showMomentDetail: Bool = false
    var isLoading: Bool = false
    var deletedMomentIds: Set<UUID> = []

    // NEW: Layout data
    private(set) var layoutData: GalaxyLayoutData = GalaxyLayoutData(
        canvasSize: CGSize(width: 800, height: 800),
        canvasCenter: CGPoint(x: 400, y: 400),
        weekClusters: [],
        constellationLines: [:],
        epochDate: Date()
    )

    // MARK: - Initialization
    init(repository: MomentRepository, screenSize: CGSize) {
        self.repository = repository
        self.coordinateEngine = GalaxyCoordinateEngine(screenSize: screenSize)
    }

    // MARK: - Data Loading
    func loadMoments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            moments = try await repository.fetchAll(
                sortedBy: SortDescriptor(\.happenedAt, order: .reverse)
            )

            // NEW: Recalculate layout
            layoutData = coordinateEngine.calculateLayout(moments: moments)
        } catch {
            print("Failed to load moments: \(error)")
        }
    }

    // MARK: - Moment Selection
    func selectMoment(_ moment: Moment) {
        selectedMoment = moment
        showMomentDetail = true
    }

    func dismissDetail() async {
        showMomentDetail = false
        selectedMoment = nil

        // Reload moments to reflect any changes made in the detail sheet
        await loadMoments()
    }

    // MARK: - Moment Deletion
    func handleMomentDeleted(_ moment: Moment) {
        // Add to deleted set for fade-out animation
        deletedMomentIds.insert(moment.clientId)

        // Remove from moments array after animation completes
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            moments.removeAll { $0.clientId == moment.clientId }
            deletedMomentIds.remove(moment.clientId)
            // Recalculate layout after deletion
            layoutData = coordinateEngine.calculateLayout(moments: moments)
        }
    }

    // MARK: - Position Calculation
    func position(for moment: Moment) -> CGPoint {
        coordinateEngine.position(
            for: moment.clientId,
            layoutData: layoutData,
            moments: moments
        )
    }

    func colorIndex(for moment: Moment) -> Int {
        coordinateEngine.colorIndex(for: moment.clientId)
    }

    // MARK: - Computed Properties
    var canvasSize: CGSize {
        layoutData.canvasSize
    }

    var isEmpty: Bool {
        moments.isEmpty
    }
}
