import Foundation
import Testing
import SwiftData
@testable import YouAreDoingGreat

// MARK: - Offline-First Flow Integration Tests
// End-to-end tests for the offline-first moment creation and sync workflow
// Tests the complete flow: create locally → background sync → AI praise update

@Suite("Offline-First Flow Integration Tests")
@MainActor
struct OfflineFirstFlowTests {
    // MARK: - Helper Properties

    var service: MomentService!
    var viewModel: MomentsListViewModel!
    var mockAPI: MockAPIClient!
    var repository: MomentRepository!
    var context: ModelContext!

    // MARK: - Setup

    init() async throws {
        context = try TestContainer.makeInMemoryContext()
        repository = SwiftDataMomentRepository(modelContext: context)
        mockAPI = MockAPIClient()
        service = MomentService(apiClient: mockAPI, repository: repository)
        viewModel = MomentsListViewModel(momentService: service, repository: repository)
    }

    // MARK: - Complete Offline-First Flow Tests

    @Test("Complete offline-first flow: create → sync → enrich")
    func completeOfflineFirstFlow() async throws {
        // 1. Create moment locally (offline state)
        let clientId = UUID()
        let localMoment = MomentFixtures.unsyncedMoment(text: "Shipped a feature")
        localMoment.clientId = clientId
        try await repository.save(localMoment)

        // Verify moment has offline praise and is not synced
        #expect(localMoment.offlinePraise.isEmpty == false)
        #expect(localMoment.isSynced == false)
        #expect(localMoment.serverId == nil)
        #expect(localMoment.praise == nil)

        // 2. Mock server response with AI praise
        let enrichedDTO = MomentFixtures.momentDTO(
            id: "server-123",
            clientId: clientId.uuidString,
            text: "Shipped a feature",
            praise: "Wow, that's incredible! Shipping features is such an accomplishment."
        )
        let response = MomentFixtures.paginatedResponse(moments: [enrichedDTO])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // 3. Sync from server (simulates background sync)
        try await service.refreshFromServer()

        // 4. Verify moment was updated with server data
        let syncedMoment = try await repository.fetch(clientId: clientId)

        #expect(syncedMoment != nil)
        #expect(syncedMoment?.serverId == "server-123")
        #expect(syncedMoment?.praise == "Wow, that's incredible! Shipping features is such an accomplishment.")
        #expect(syncedMoment?.isSynced == true)
        #expect(syncedMoment?.text == "Shipped a feature")
    }

    @Test("Moment created offline shows immediately in UI")
    func offlineMomentShowsImmediately() async throws {
        // Create moment offline
        let moment = MomentFixtures.unsyncedMoment(text: "Local work")
        try await repository.save(moment)

        // Mock empty server response
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Load moments in ViewModel
        await viewModel.loadMoments()

        // Verify moment appears immediately (from local storage)
        #expect(viewModel.moments.count == 1)
        #expect(viewModel.moments.first?.text == "Local work")
        #expect(viewModel.moments.first?.isSynced == false)
    }

    @Test("Background refresh updates moments with AI praise")
    func backgroundRefreshUpdatesWithPraise() async throws {
        // Pre-populate with unsynced moment
        let clientId = UUID()
        let unsyncedMoment = MomentFixtures.unsyncedMoment(text: "Waiting for praise")
        unsyncedMoment.clientId = clientId
        try await repository.save(unsyncedMoment)

        // Mock server response with AI praise
        let enrichedDTO = MomentFixtures.momentDTO(
            clientId: clientId.uuidString,
            text: "Waiting for praise",
            praise: "You're doing great! Keep it up."
        )
        let response = MomentFixtures.paginatedResponse(moments: [enrichedDTO])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Track background refresh completion
        var backgroundRefreshCompleted = false

        // Load moments (triggers background refresh)
        _ = try await service.loadInitialMoments {
            backgroundRefreshCompleted = true
        }

        // Wait for background refresh
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Verify background refresh completed and moment was updated
        #expect(backgroundRefreshCompleted == true)

        let updatedMoment = try await repository.fetch(clientId: clientId)
        #expect(updatedMoment?.praise == "You're doing great! Keep it up.")
        #expect(updatedMoment?.isSynced == true)
    }

    // MARK: - Multiple Moment Sync Tests

    @Test("Multiple unsynced moments sync correctly")
    func multipleMomentsSync() async throws {
        // Create multiple unsynced moments
        let moment1 = MomentFixtures.unsyncedMoment(text: "Moment 1")
        let moment2 = MomentFixtures.unsyncedMoment(text: "Moment 2")
        let moment3 = MomentFixtures.unsyncedMoment(text: "Moment 3")

        try await repository.save(moment1)
        try await repository.save(moment2)
        try await repository.save(moment3)

        // Mock server response with all three enriched
        let dto1 = MomentFixtures.momentDTO(
            clientId: moment1.clientId.uuidString,
            text: "Moment 1",
            praise: "Praise 1"
        )
        let dto2 = MomentFixtures.momentDTO(
            clientId: moment2.clientId.uuidString,
            text: "Moment 2",
            praise: "Praise 2"
        )
        let dto3 = MomentFixtures.momentDTO(
            clientId: moment3.clientId.uuidString,
            text: "Moment 3",
            praise: "Praise 3"
        )
        let response = MomentFixtures.paginatedResponse(moments: [dto1, dto2, dto3])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify all moments synced
        let allMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(allMoments.count == 3)
        #expect(allMoments.allSatisfy { $0.isSynced })
        #expect(allMoments.allSatisfy { $0.praise != nil })
    }

    // MARK: - Partial Enrichment Tests

    @Test("Moment without praise stays unsynced until enriched")
    func partialEnrichmentStaysUnsynced() async throws {
        let clientId = UUID()
        let moment = MomentFixtures.unsyncedMoment(text: "Being enriched")
        moment.clientId = clientId
        try await repository.save(moment)

        // Mock server response without praise (enrichment in progress)
        let dtoWithoutPraise = MomentFixtures.momentDTO(
            clientId: clientId.uuidString,
            text: "Being enriched",
            praise: nil // Enrichment not complete
        )
        let response = MomentFixtures.paginatedResponse(moments: [dtoWithoutPraise])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify moment is NOT marked as synced (waiting for praise)
        let updatedMoment = try await repository.fetch(clientId: clientId)
        #expect(updatedMoment?.isSynced == false)
        #expect(updatedMoment?.praise == nil)
    }

    @Test("Moment with empty praise string stays unsynced")
    func emptyPraiseStaysUnsynced() async throws {
        let clientId = UUID()
        let moment = MomentFixtures.unsyncedMoment(text: "Empty praise")
        moment.clientId = clientId
        try await repository.save(moment)

        // Mock server response with empty praise string
        let dtoWithEmptyPraise = MomentFixtures.momentDTO(
            clientId: clientId.uuidString,
            text: "Empty praise",
            praise: "" // Empty string
        )
        let response = MomentFixtures.paginatedResponse(moments: [dtoWithEmptyPraise])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify moment is NOT marked as synced
        let updatedMoment = try await repository.fetch(clientId: clientId)
        #expect(updatedMoment?.isSynced == false)
    }

    // MARK: - Server-Only Moments Tests

    @Test("Server-only moments (not created locally) sync correctly")
    func serverOnlyMomentsSync() async throws {
        // Mock server response with moment that doesn't exist locally
        let serverOnlyDTO = MomentFixtures.momentDTO(
            id: "server-456",
            text: "Server only moment",
            praise: "Created elsewhere!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [serverOnlyDTO])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify server moment was created locally
        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1)
        #expect(moments.first?.serverId == "server-456")
        #expect(moments.first?.text == "Server only moment")
        #expect(moments.first?.isSynced == true)
    }

    // MARK: - Conflict Resolution Tests

    @Test("Update existing moment by server ID (prefer server data)")
    func updateExistingByServerId() async throws {
        // Create local moment with server ID
        let moment = MomentFixtures.syncedMoment(text: "Old version")
        moment.serverId = "server-789"
        moment.praise = "Old praise"
        try await repository.save(moment)

        // Mock server response with updated version
        let updatedDTO = MomentFixtures.momentDTO(
            id: "server-789",
            text: "New version",
            praise: "New praise!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [updatedDTO])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify moment was updated (not duplicated)
        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1) // No duplicate
        #expect(moments.first?.text == "New version")
        #expect(moments.first?.praise == "New praise!")
    }

    @Test("Update existing moment by client ID (link server ID)")
    func updateExistingByClientId() async throws {
        // Create unsynced local moment
        let clientId = UUID()
        let moment = MomentFixtures.unsyncedMoment(text: "Local only")
        moment.clientId = clientId
        try await repository.save(moment)

        // Mock server response with server ID for same client ID
        let linkedDTO = MomentFixtures.momentDTO(
            id: "new-server-id",
            clientId: clientId.uuidString,
            text: "Local only",
            praise: "Now synced!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [linkedDTO])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify moment was updated and linked to server
        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1) // No duplicate
        #expect(moments.first?.serverId == "new-server-id")
        #expect(moments.first?.clientId == clientId)
        #expect(moments.first?.isSynced == true)
    }

    // MARK: - Mixed State Tests

    @Test("Mixed synced and unsynced moments handled correctly")
    func mixedSyncedUnsyncedMoments() async throws {
        // Create one synced and one unsynced moment
        let syncedMoment = MomentFixtures.syncedMoment(text: "Already synced")
        syncedMoment.serverId = "server-100"

        let unsyncedMoment = MomentFixtures.unsyncedMoment(text: "Not yet synced")

        try await repository.save(syncedMoment)
        try await repository.save(unsyncedMoment)

        // Mock server response with updated synced moment and new unsynced moment enriched
        let dto1 = MomentFixtures.momentDTO(
            id: "server-100",
            text: "Already synced",
            praise: "Still great!"
        )
        let dto2 = MomentFixtures.momentDTO(
            clientId: unsyncedMoment.clientId.uuidString,
            text: "Not yet synced",
            praise: "Now synced!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [dto1, dto2])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        // Sync from server
        try await service.refreshFromServer()

        // Verify both moments synced correctly
        let allMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(allMoments.count == 2)
        #expect(allMoments.allSatisfy { $0.isSynced })
    }
}
