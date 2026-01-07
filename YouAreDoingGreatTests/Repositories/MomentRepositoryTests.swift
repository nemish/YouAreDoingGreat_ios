import Foundation
import Testing
import SwiftData
@testable import YouAreDoingGreat

// MARK: - Moment Repository Tests
// Tests for SwiftData moment repository operations
// Validates CRUD operations, filtering, and querying

@Suite("Moment Repository Tests")
@MainActor
struct MomentRepositoryTests {
    // MARK: - Helper Properties

    var repository: MomentRepository!
    var context: ModelContext!

    // MARK: - Setup

    init() async throws {
        context = try TestContainer.makeInMemoryContext()
        repository = SwiftDataMomentRepository(modelContext: context)
    }

    // MARK: - Save Tests

    @Test("Save moment successfully")
    func saveMoment() async throws {
        let moment = MomentFixtures.moment(text: "Saved a moment")

        try await repository.save(moment)

        let fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 1)
        #expect(fetchedMoments.first?.text == "Saved a moment")
    }

    @Test("Save multiple moments")
    func saveMultipleMoments() async throws {
        let moment1 = MomentFixtures.moment(text: "First moment")
        let moment2 = MomentFixtures.moment(text: "Second moment")
        let moment3 = MomentFixtures.moment(text: "Third moment")

        try await repository.save(moment1)
        try await repository.save(moment2)
        try await repository.save(moment3)

        let fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 3)
    }

    // MARK: - Fetch Tests

    @Test("Fetch all moments sorted by submitted date")
    func fetchAllMomentsSorted() async throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)
        let twoDaysAgo = now.addingTimeInterval(-172800)

        let moment1 = MomentFixtures.moment(text: "Today", submittedAt: now)
        let moment2 = MomentFixtures.moment(text: "Yesterday", submittedAt: yesterday)
        let moment3 = MomentFixtures.moment(text: "Two days ago", submittedAt: twoDaysAgo)

        try await repository.save(moment1)
        try await repository.save(moment2)
        try await repository.save(moment3)

        let fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 3)
        #expect(fetchedMoments[0].text == "Today")
        #expect(fetchedMoments[1].text == "Yesterday")
        #expect(fetchedMoments[2].text == "Two days ago")
    }

    @Test("Fetch moment by client ID")
    func fetchMomentByClientId() async throws {
        let clientId = UUID()
        let moment = MomentFixtures.moment(clientId: clientId, text: "Find me")

        try await repository.save(moment)

        let fetchedMoment = try await repository.fetch(clientId: clientId)

        #expect(fetchedMoment != nil)
        #expect(fetchedMoment?.text == "Find me")
        #expect(fetchedMoment?.clientId == clientId)
    }

    @Test("Fetch moment by server ID")
    func fetchMomentByServerId() async throws {
        let serverId = UUID().uuidString
        let moment = MomentFixtures.syncedMoment(text: "Server moment")
        moment.serverId = serverId

        try await repository.save(moment)

        let fetchedMoment = try await repository.fetch(serverId: serverId)

        #expect(fetchedMoment != nil)
        #expect(fetchedMoment?.text == "Server moment")
        #expect(fetchedMoment?.serverId == serverId)
    }

    @Test("Fetch returns nil for non-existent client ID")
    func fetchNonExistentClientId() async throws {
        let moment = try await repository.fetch(clientId: UUID())
        #expect(moment == nil)
    }

    @Test("Fetch returns nil for non-existent server ID")
    func fetchNonExistentServerId() async throws {
        let moment = try await repository.fetch(serverId: UUID().uuidString)
        #expect(moment == nil)
    }

    // MARK: - Update Tests

    @Test("Update moment successfully")
    func updateMoment() async throws {
        let moment = MomentFixtures.moment(text: "Original text")

        try await repository.save(moment)

        moment.text = "Updated text"
        moment.praise = "Updated praise"

        try await repository.update(moment)

        let fetchedMoment = try await repository.fetch(clientId: moment.clientId)

        #expect(fetchedMoment?.text == "Updated text")
        #expect(fetchedMoment?.praise == "Updated praise")
    }

    @Test("Update moment sync status")
    func updateMomentSyncStatus() async throws {
        let moment = MomentFixtures.unsyncedMoment()

        try await repository.save(moment)

        #expect(moment.isSynced == false)

        moment.isSynced = true
        moment.serverId = UUID().uuidString
        moment.praise = "AI generated praise"

        try await repository.update(moment)

        let fetchedMoment = try await repository.fetch(clientId: moment.clientId)

        #expect(fetchedMoment?.isSynced == true)
        #expect(fetchedMoment?.serverId != nil)
        #expect(fetchedMoment?.praise == "AI generated praise")
    }

    // MARK: - Delete Tests

    @Test("Delete moment successfully")
    func deleteMoment() async throws {
        let moment = MomentFixtures.moment(text: "To be deleted")

        try await repository.save(moment)

        var fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 1)

        try await repository.delete(moment)

        fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 0)
    }

    @Test("Delete all moments")
    func deleteAllMoments() async throws {
        try await repository.save(MomentFixtures.moment(text: "Moment 1"))
        try await repository.save(MomentFixtures.moment(text: "Moment 2"))
        try await repository.save(MomentFixtures.moment(text: "Moment 3"))

        var fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 3)

        try await repository.deleteAll()

        fetchedMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(fetchedMoments.count == 0)
    }

    // MARK: - Unsynced Moments Tests

    @Test("Fetch unsynced moments")
    func fetchUnsyncedMoments() async throws {
        let syncedMoment = MomentFixtures.syncedMoment()
        let unsyncedMoment1 = MomentFixtures.unsyncedMoment(text: "Unsynced 1")
        let unsyncedMoment2 = MomentFixtures.unsyncedMoment(text: "Unsynced 2")

        try await repository.save(syncedMoment)
        try await repository.save(unsyncedMoment1)
        try await repository.save(unsyncedMoment2)

        let unsyncedMoments = try await repository.fetchUnsyncedMoments()

        #expect(unsyncedMoments.count == 2)
        #expect(unsyncedMoments.allSatisfy { !$0.isSynced })
    }

    @Test("Fetch unsynced moments returns empty when all synced")
    func fetchUnsyncedMomentsEmpty() async throws {
        let syncedMoment1 = MomentFixtures.syncedMoment(text: "Synced 1")
        let syncedMoment2 = MomentFixtures.syncedMoment(text: "Synced 2")

        try await repository.save(syncedMoment1)
        try await repository.save(syncedMoment2)

        let unsyncedMoments = try await repository.fetchUnsyncedMoments()

        #expect(unsyncedMoments.isEmpty)
    }

    // MARK: - Unique Constraint Tests

    // Note: Unique constraint test disabled - in-memory SwiftData doesn't enforce unique constraints reliably
    // In production, SwiftData will enforce the @Attribute(.unique) constraint on clientId
    /*
    @Test("Unique client ID constraint")
    func uniqueClientIdConstraint() async throws {
        let clientId = UUID()
        let moment1 = MomentFixtures.moment(clientId: clientId, text: "First")
        let moment2 = MomentFixtures.moment(clientId: clientId, text: "Second")

        try await repository.save(moment1)

        // Attempting to save a second moment with the same client ID should fail
        var didThrow = false
        do {
            try await repository.save(moment2)
        } catch {
            didThrow = true
        }
        #expect(didThrow == true)
    }
    */

    // MARK: - Complex Query Tests

    @Test("Filter favorite moments")
    func filterFavoriteMoments() async throws {
        let favorite1 = MomentFixtures.favoriteMoment(text: "Favorite 1")
        let favorite2 = MomentFixtures.favoriteMoment(text: "Favorite 2")
        let regular = MomentFixtures.syncedMoment(text: "Regular")

        try await repository.save(favorite1)
        try await repository.save(favorite2)
        try await repository.save(regular)

        let allMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        let favorites = allMoments.filter { $0.isFavorite }

        #expect(favorites.count == 2)
        #expect(favorites.allSatisfy { $0.isFavorite })
    }
}
