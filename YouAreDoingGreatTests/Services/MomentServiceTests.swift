import Foundation
import Testing
import SwiftData
@testable import YouAreDoingGreat

// MARK: - Moment Service Tests
// Tests for MomentService business logic
// Validates offline-first sync, pagination, and favorite toggling

@Suite("Moment Service Tests")
@MainActor
struct MomentServiceTests {
    // MARK: - Helper Properties

    var service: MomentService!
    var mockAPI: MockAPIClient!
    var repository: MomentRepository!
    var context: ModelContext!

    // MARK: - Setup

    init() async throws {
        context = try TestContainer.makeInMemoryContext()
        repository = SwiftDataMomentRepository(modelContext: context)
        mockAPI = MockAPIClient()
        service = MomentService(apiClient: mockAPI, repository: repository)
    }

    // MARK: - Load Initial Moments Tests

    @Test("Load initial moments from local storage")
    func loadInitialMomentsLocal() async throws {
        // Pre-populate local storage
        let localMoment = MomentFixtures.syncedMoment(text: "Local moment")
        try await repository.save(localMoment)

        // Mock empty server response
        let emptyResponse = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: emptyResponse)

        let moments = try await service.loadInitialMoments()

        #expect(moments.count == 1)
        #expect(moments.first?.text == "Local moment")
    }

    @Test("Load initial moments syncs from server in background")
    func loadInitialMomentsServerSync() async throws {
        // Mock server response with new moment
        let serverMoment = MomentFixtures.momentDTO(
            text: "Server moment",
            praise: "Great work!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [serverMoment])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        var backgroundRefreshCompleted = false
        let moments = try await service.loadInitialMoments {
            backgroundRefreshCompleted = true
        }

        // Wait for background refresh to complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        #expect(backgroundRefreshCompleted == true)
        #expect(mockAPI.didRequest(endpoint: .moments(cursor: nil, limit: 50, isFavorite: nil)))
    }

    // MARK: - Refresh From Server Tests

    @Test("Refresh from server updates local storage")
    func refreshFromServer() async throws {
        // Pre-populate local storage with unsynced moment
        let localMoment = MomentFixtures.unsyncedMoment(text: "Local only")
        try await repository.save(localMoment)

        // Mock server response with enriched version
        let enrichedMoment = MomentFixtures.momentDTO(
            clientId: localMoment.clientId.uuidString,
            text: "Local only",
            praise: "Amazing progress!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [enrichedMoment])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        try await service.refreshFromServer()

        // Verify moment was updated with AI praise
        let updatedMoment = try await repository.fetch(clientId: localMoment.clientId)
        #expect(updatedMoment?.praise == "Amazing progress!")
        #expect(updatedMoment?.isSynced == true)
    }

    @Test("Refresh updates pagination state")
    func refreshUpdatesPagination() async throws {
        let moment1 = MomentFixtures.momentDTO(text: "Moment 1")
        let response = MomentFixtures.paginatedResponse(
            moments: [moment1],
            nextCursor: "cursor123",
            hasNextPage: true
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        try await service.refreshFromServer()

        #expect(service.nextCursor == "cursor123")
        #expect(service.hasNextPage == true)
    }

    @Test("Refresh with favorites filter enabled")
    func refreshWithFavoritesFilter() async throws {
        service.setFavoritesFilter(true)

        let favoriteMoment = MomentFixtures.momentDTO(text: "Favorite", isFavorite: true)
        let response = MomentFixtures.paginatedResponse(moments: [favoriteMoment])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50&isFavorite=true", response: response)

        try await service.refreshFromServer()

        #expect(mockAPI.didRequest(endpoint: .moments(cursor: nil, limit: 50, isFavorite: true)))
    }

    // MARK: - Load Next Page Tests

    @Test("Load next page with cursor")
    func loadNextPage() async throws {
        // Set initial pagination state
        service.nextCursor = "cursor123"
        service.hasNextPage = true

        let moment2 = MomentFixtures.momentDTO(text: "Page 2 moment")
        let response = MomentFixtures.paginatedResponse(
            moments: [moment2],
            nextCursor: nil,
            hasNextPage: false
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=20&cursor=cursor123", response: response)

        let moments = try await service.loadNextPage()

        #expect(moments.count == 1)
        #expect(moments.first?.text == "Page 2 moment")
        #expect(service.hasNextPage == false)
        #expect(service.nextCursor == nil)
    }

    @Test("Load next page returns empty when no more pages")
    func loadNextPageEmpty() async throws {
        // No next page
        service.hasNextPage = false

        let moments = try await service.loadNextPage()

        #expect(moments.isEmpty)
        #expect(mockAPI.requestHistory.isEmpty)
    }

    @Test("Load next page updates limit reached state")
    func loadNextPageLimitReached() async throws {
        service.nextCursor = "cursor123"
        service.hasNextPage = true

        let moment = MomentFixtures.momentDTO(text: "Limit reached")
        let response = MomentFixtures.paginatedResponse(
            moments: [moment],
            limitReached: true
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=20&cursor=cursor123", response: response)

        _ = try await service.loadNextPage()

        #expect(service.isLimitReached == true)
    }

    // MARK: - Favorites Filter Tests

    @Test("Set favorites filter resets pagination")
    func setFavoritesFilterResetsPagination() async throws {
        // Set pagination state
        service.nextCursor = "cursor123"
        service.hasNextPage = true
        service.isLimitReached = true

        service.setFavoritesFilter(true)

        #expect(service.isShowingFavoritesOnly == true)
        #expect(service.nextCursor == nil)
        #expect(service.hasNextPage == false)
        #expect(service.isLimitReached == false)
    }

    // MARK: - Toggle Favorite Tests

    @Test("Toggle favorite updates local and syncs to server")
    func toggleFavorite() async throws {
        let moment = MomentFixtures.syncedMoment(text: "To favorite")
        moment.serverId = "server123"
        moment.isFavorite = false
        try await repository.save(moment)

        // Mock update response
        struct UpdateResponse: Encodable {
            let message: String
        }
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server123",
            response: UpdateResponse(message: "Updated")
        )

        try await service.toggleFavorite(moment)

        #expect(moment.isFavorite == true)
        #expect(mockAPI.didRequest(endpoint: .updateMoment(id: "server123")))
    }

    @Test("Toggle favorite on unsynced moment updates locally only")
    func toggleFavoriteUnsynced() async throws {
        let moment = MomentFixtures.unsyncedMoment(text: "No server ID")
        moment.isFavorite = false
        try await repository.save(moment)

        try await service.toggleFavorite(moment)

        #expect(moment.isFavorite == true)
        #expect(mockAPI.requestHistory.isEmpty) // No server request
    }

    // MARK: - Delete Moment Tests

    @Test("Delete moment removes from local and server")
    func deleteMoment() async throws {
        let moment = MomentFixtures.syncedMoment(text: "To delete")
        moment.serverId = "server123"
        try await repository.save(moment)

        // Mock delete response
        struct DeleteResponse: Encodable {}
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server123",
            response: DeleteResponse()
        )

        try await service.deleteMoment(clientId: moment.clientId, serverId: moment.serverId)

        let fetchedMoment = try await repository.fetch(clientId: moment.clientId)
        #expect(fetchedMoment == nil)
        #expect(mockAPI.didRequest(endpoint: .deleteMoment(id: "server123")))
    }

    @Test("Delete unsynced moment removes from local only")
    func deleteUnsyncedMoment() async throws {
        let moment = MomentFixtures.unsyncedMoment(text: "Local only")
        try await repository.save(moment)

        try await service.deleteMoment(clientId: moment.clientId, serverId: moment.serverId)

        let fetchedMoment = try await repository.fetch(clientId: moment.clientId)
        #expect(fetchedMoment == nil)
        #expect(mockAPI.requestHistory.isEmpty) // No server request
    }

    // MARK: - Sync Moment Tests

    @Test("Sync moment creates new when not exists locally")
    func syncMomentCreatesNew() async throws {
        let dto = MomentFixtures.momentDTO(
            id: "server123",
            text: "Server moment",
            praise: "Well done!"
        )

        // Use reflection to call private syncMoment method
        // For this test, we'll test via refreshFromServer
        let response = MomentFixtures.paginatedResponse(moments: [dto])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        try await service.refreshFromServer()

        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1)
        #expect(moments.first?.serverId == "server123")
        #expect(moments.first?.text == "Server moment")
        #expect(moments.first?.praise == "Well done!")
    }

    @Test("Sync moment updates existing by server ID")
    func syncMomentUpdatesExistingByServerId() async throws {
        // Create existing moment with server ID
        let existingMoment = MomentFixtures.syncedMoment(text: "Old text")
        existingMoment.serverId = "server123"
        existingMoment.praise = "Old praise"
        try await repository.save(existingMoment)

        // Server returns updated version
        let dto = MomentFixtures.momentDTO(
            id: "server123",
            text: "Updated text",
            praise: "New praise!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [dto])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        try await service.refreshFromServer()

        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1) // Should update, not create new
        #expect(moments.first?.text == "Updated text")
        #expect(moments.first?.praise == "New praise!")
    }

    @Test("Sync moment updates existing by client ID")
    func syncMomentUpdatesExistingByClientId() async throws {
        // Create unsynced moment
        let clientId = UUID()
        let existingMoment = MomentFixtures.unsyncedMoment(text: "Waiting for sync")
        existingMoment.clientId = clientId
        try await repository.save(existingMoment)

        // Server returns enriched version with client ID
        let dto = MomentFixtures.momentDTO(
            id: "server123",
            clientId: clientId.uuidString,
            text: "Waiting for sync",
            praise: "Synced successfully!"
        )
        let response = MomentFixtures.paginatedResponse(moments: [dto])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        try await service.refreshFromServer()

        let moments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )

        #expect(moments.count == 1) // Should update, not create new
        #expect(moments.first?.serverId == "server123")
        #expect(moments.first?.praise == "Synced successfully!")
        #expect(moments.first?.isSynced == true)
    }

    // MARK: - Restore Moment Tests

    @Test("Restore moment succeeds and syncs to local storage")
    func restoreMoment_Success() async throws {
        let serverId = "server123"

        // Mock restore response
        let restoredMomentDTO = MomentFixtures.momentDTO(
            id: serverId,
            clientId: UUID().uuidString,
            text: "Restored moment",
            praise: "Welcome back!"
        )
        struct RestoreResponse: Encodable {
            let item: EncodableMomentDTO
        }
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/\(serverId)/restore",
            response: RestoreResponse(item: restoredMomentDTO)
        )

        let restoredMoment = try await service.restoreMoment(serverId: serverId)

        #expect(restoredMoment.serverId == serverId)
        #expect(restoredMoment.text == "Restored moment")
        #expect(restoredMoment.praise == "Welcome back!")
        #expect(mockAPI.didRequest(endpoint: .restoreMoment(id: serverId)))

        // Verify moment is saved in local storage
        let fetchedMoment = try await repository.fetch(serverId: serverId)
        #expect(fetchedMoment != nil)
        #expect(fetchedMoment?.text == "Restored moment")
    }

    @Test("Restore moment updates existing local moment")
    func restoreMoment_UpdatesLocalStorage() async throws {
        let serverId = "server123"
        let clientId = UUID()

        // Pre-populate with deleted moment (exists locally but marked as deleted)
        let existingMoment = MomentFixtures.syncedMoment(text: "Old version")
        existingMoment.serverId = serverId
        existingMoment.clientId = clientId
        try await repository.save(existingMoment)

        // Mock restore response
        let restoredMomentDTO = MomentFixtures.momentDTO(
            id: serverId,
            clientId: clientId.uuidString,
            text: "Restored moment",
            praise: "Back again!"
        )
        struct RestoreResponse: Encodable {
            let item: EncodableMomentDTO
        }
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/\(serverId)/restore",
            response: RestoreResponse(item: restoredMomentDTO)
        )

        let restoredMoment = try await service.restoreMoment(serverId: serverId)

        #expect(restoredMoment.serverId == serverId)
        #expect(restoredMoment.clientId == clientId)
        #expect(restoredMoment.text == "Restored moment")
        #expect(restoredMoment.praise == "Back again!")

        // Verify only one moment exists (updated, not created new)
        let allMoments = try await repository.fetchAll(
            sortedBy: SortDescriptor(\.submittedAt, order: .reverse)
        )
        #expect(allMoments.count == 1)
    }

    @Test("Restore moment handles network error")
    func restoreMoment_NetworkError() async throws {
        let serverId = "server123"

        // Mock network error
        enum TestError: Error {
            case networkFailure
        }
        mockAPI.setError(
            for: "\(AppConfig.apiBaseURL)/moments/\(serverId)/restore",
            error: TestError.networkFailure
        )

        do {
            _ = try await service.restoreMoment(serverId: serverId)
            Issue.record("Expected restore to throw error")
        } catch {
            // Expected error - test passes
            #expect(true)
        }
    }
}
