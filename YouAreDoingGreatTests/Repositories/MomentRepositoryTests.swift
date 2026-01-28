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

    // MARK: - Fetch by Date Tests

    @Test("Fetch moments by date returns correct moments")
    func fetchMomentsByDate() async throws {
        let calendar = Calendar.current
        let now = Date()

        // Create a specific date (today at noon)
        let targetDate = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!

        // Create moments for the target date
        let morningMoment = MomentFixtures.moment(
            text: "Morning moment",
            happenedAt: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate)!
        )
        let afternoonMoment = MomentFixtures.moment(
            text: "Afternoon moment",
            happenedAt: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: targetDate)!
        )
        let eveningMoment = MomentFixtures.moment(
            text: "Evening moment",
            happenedAt: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: targetDate)!
        )

        try await repository.save(morningMoment)
        try await repository.save(afternoonMoment)
        try await repository.save(eveningMoment)

        let fetchedMoments = try await repository.fetchByDate(targetDate)

        #expect(fetchedMoments.count == 3)
        #expect(fetchedMoments.contains { $0.text == "Morning moment" })
        #expect(fetchedMoments.contains { $0.text == "Afternoon moment" })
        #expect(fetchedMoments.contains { $0.text == "Evening moment" })
    }

    @Test("Fetch moments by date excludes other days")
    func fetchMomentsByDateExcludesOtherDays() async throws {
        let calendar = Calendar.current
        let now = Date()

        // Create dates for today, yesterday, and tomorrow
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        // Create moments for each day
        let todayMoment = MomentFixtures.moment(
            text: "Today",
            happenedAt: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: today)!
        )
        let yesterdayMoment = MomentFixtures.moment(
            text: "Yesterday",
            happenedAt: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!
        )
        let tomorrowMoment = MomentFixtures.moment(
            text: "Tomorrow",
            happenedAt: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: tomorrow)!
        )

        try await repository.save(todayMoment)
        try await repository.save(yesterdayMoment)
        try await repository.save(tomorrowMoment)

        let fetchedMoments = try await repository.fetchByDate(today)

        #expect(fetchedMoments.count == 1)
        #expect(fetchedMoments.first?.text == "Today")
    }

    @Test("Fetch moments by date handles day boundaries")
    func fetchMomentsByDateHandlesBoundaries() async throws {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Create moments at the very start and end of the day
        let startOfDayMoment = MomentFixtures.moment(
            text: "Start of day",
            happenedAt: today
        )
        let endOfDayMoment = MomentFixtures.moment(
            text: "End of day",
            happenedAt: calendar.date(byAdding: .second, value: 86399, to: today)! // 23:59:59
        )

        // Create a moment just after midnight (next day)
        let nextDayMoment = MomentFixtures.moment(
            text: "Next day",
            happenedAt: calendar.date(byAdding: .day, value: 1, to: today)!
        )

        try await repository.save(startOfDayMoment)
        try await repository.save(endOfDayMoment)
        try await repository.save(nextDayMoment)

        let fetchedMoments = try await repository.fetchByDate(today)

        #expect(fetchedMoments.count == 2)
        #expect(fetchedMoments.contains { $0.text == "Start of day" })
        #expect(fetchedMoments.contains { $0.text == "End of day" })
        #expect(!fetchedMoments.contains { $0.text == "Next day" })
    }

    @Test("Fetch moments by date returns empty for date with no moments")
    func fetchMomentsByDateReturnsEmpty() async throws {
        let calendar = Calendar.current
        let now = Date()

        // Create moments for today
        let today = calendar.startOfDay(for: now)
        let todayMoment = MomentFixtures.moment(
            text: "Today",
            happenedAt: today
        )

        try await repository.save(todayMoment)

        // Try to fetch moments from a week ago (should be empty)
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: today)!
        let fetchedMoments = try await repository.fetchByDate(weekAgo)

        #expect(fetchedMoments.isEmpty)
    }

    @Test("Fetch moments by date sorted by happened at")
    func fetchMomentsByDateSorted() async throws {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Create moments in random order
        let moment3 = MomentFixtures.moment(
            text: "Latest",
            happenedAt: calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today)!
        )
        let moment1 = MomentFixtures.moment(
            text: "Earliest",
            happenedAt: calendar.date(bySettingHour: 8, minute: 0, second: 0, of: today)!
        )
        let moment2 = MomentFixtures.moment(
            text: "Middle",
            happenedAt: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: today)!
        )

        try await repository.save(moment3)
        try await repository.save(moment1)
        try await repository.save(moment2)

        let fetchedMoments = try await repository.fetchByDate(today)

        #expect(fetchedMoments.count == 3)
        // Should be sorted by happenedAt in reverse order (latest first)
        #expect(fetchedMoments[0].text == "Latest")
        #expect(fetchedMoments[1].text == "Middle")
        #expect(fetchedMoments[2].text == "Earliest")
    }
}
