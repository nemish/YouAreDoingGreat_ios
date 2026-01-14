import Foundation
import SwiftData
import OSLog

private let logger = Logger(subsystem: "ee.required.you-are-doing-great", category: "repository")

// MARK: - SwiftData Moment Repository
// Concrete implementation of MomentRepository using SwiftData

@MainActor
final class SwiftDataMomentRepository: MomentRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - MomentRepository Implementation

    func save(_ moment: Moment) async throws {
        modelContext.insert(moment)
        try modelContext.save()
        logger.info("Saved moment with clientId: \(moment.clientId.uuidString)")
    }

    func fetchAll(sortedBy sortDescriptor: SortDescriptor<Moment>) async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            sortBy: [sortDescriptor]
        )
        let moments = try modelContext.fetch(descriptor)
        logger.info("Fetched \(moments.count) moments")
        return moments
    }

    func delete(_ moment: Moment) async throws {
        // Capture clientId BEFORE deletion - SwiftData objects become invalid after delete
        let clientId = moment.clientId
        modelContext.delete(moment)
        try modelContext.save()
        logger.info("Deleted moment with clientId: \(clientId.uuidString)")
    }

    func update(_ moment: Moment) async throws {
        try modelContext.save()
    }

    func fetchUnsyncedMoments() async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate<Moment> { moment in
                moment.isSynced == false
            },
            sortBy: [SortDescriptor(\.submittedAt, order: .reverse)]
        )
        let moments = try modelContext.fetch(descriptor)
        logger.info("Fetched \(moments.count) unsynced moments")
        return moments
    }

    func fetch(clientId: UUID) async throws -> Moment? {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate<Moment> { moment in
                moment.clientId == clientId
            }
        )
        let moments = try modelContext.fetch(descriptor)
        return moments.first
    }

    func fetch(serverId: String) async throws -> Moment? {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate<Moment> { moment in
                moment.serverId == serverId
            }
        )
        let moments = try modelContext.fetch(descriptor)
        return moments.first
    }

    func deleteAll() async throws {
        let descriptor = FetchDescriptor<Moment>()
        let allMoments = try modelContext.fetch(descriptor)

        logger.info("Deleting all \(allMoments.count) moments from local database")

        for moment in allMoments {
            modelContext.delete(moment)
        }

        try modelContext.save()
        logger.info("Successfully cleared local database")
    }

    func fetchByTag(_ tag: String) async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate<Moment> { moment in
                moment.tags.contains(tag)
            },
            sortBy: [SortDescriptor(\.happenedAt, order: .reverse)]
        )
        let moments = try modelContext.fetch(descriptor)
        logger.info("Fetched \(moments.count) moments with tag: \(tag)")
        return moments
    }
}
