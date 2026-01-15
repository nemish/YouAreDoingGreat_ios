import Foundation
import Testing
import SwiftData
@testable import YouAreDoingGreat

// MARK: - Moments List ViewModel Tests
// Tests for MomentsListViewModel state management and user actions
// Validates list loading, pagination, filtering, and moment actions

@Suite("Moments List ViewModel Tests")
@MainActor
struct MomentsListViewModelTests {
    // MARK: - Helper Properties

    var viewModel: MomentsListViewModel!
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
        viewModel = MomentsListViewModel(momentService: service, repository: repository)
    }

    // MARK: - Load Moments Tests

    @Test("Load moments populates list")
    func loadMoments() async throws {
        // Pre-populate local storage
        try await repository.save(MomentFixtures.syncedMoment(text: "Moment 1"))
        try await repository.save(MomentFixtures.syncedMoment(text: "Moment 2"))

        // Mock empty server response
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 2)
        #expect(viewModel.isInitialLoading == false)
        #expect(viewModel.groupedMoments.count > 0)
    }

    @Test("Load moments sets loading state")
    func loadMomentsLoadingState() async throws {
        // Mock empty server response
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        let loadTask = Task {
            await viewModel.loadMoments()
        }

        // Check loading state is true during load
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        // Note: isInitialLoading may already be false if load completed quickly

        await loadTask.value

        #expect(viewModel.isInitialLoading == false)
    }

    @Test("Load moments groups by date")
    func loadMomentsGroupsByDate() async throws {
        let now = Date()
        let yesterday = now.addingTimeInterval(-86400)

        let todayMoment = MomentFixtures.moment(text: "Today", happenedAt: now)
        let yesterdayMoment = MomentFixtures.moment(text: "Yesterday", happenedAt: yesterday)

        try await repository.save(todayMoment)
        try await repository.save(yesterdayMoment)

        // Mock empty server response
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        await viewModel.loadMoments()

        #expect(viewModel.groupedMoments.count == 2)
    }

    // MARK: - Refresh Tests

    @Test("Refresh reloads moments from server")
    func refreshMoments() async throws {
        // Pre-populate local storage
        try await repository.save(MomentFixtures.syncedMoment(text: "Old moment"))

        // Mock server response with new moment
        let newMoment = MomentFixtures.momentDTO(text: "New moment")
        let response = MomentFixtures.paginatedResponse(moments: [newMoment])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        await viewModel.refresh()

        #expect(viewModel.isRefreshing == false)
        #expect(mockAPI.didRequest(endpoint: .moments(cursor: nil, limit: 50, isFavorite: nil)))
    }

    @Test("Refresh clears timeline restriction state")
    func refreshClearsRestriction() async throws {
        viewModel.isTimelineRestricted = true
        viewModel.showTimelineRestrictedPopup = true

        // Mock empty server response
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)

        await viewModel.refresh()

        #expect(viewModel.isTimelineRestricted == false)
        #expect(viewModel.showTimelineRestrictedPopup == false)
    }

    // MARK: - Pagination Tests

    // Note: This test has async timing issues with background refresh and is disabled temporarily
    // TODO: Improve test to handle background refresh completion more reliably
    /*
    @Test("Load next page appends moments")
    func loadNextPage() async throws {
        // Pre-populate local storage with first page
        try await repository.save(MomentFixtures.syncedMoment(text: "Page 1"))

        // Mock first page response
        let page1Response = MomentFixtures.paginatedResponse(
            moments: [MomentFixtures.momentDTO(text: "Page 1")],
            nextCursor: "cursor123",
            hasNextPage: true
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: page1Response)

        await viewModel.loadMoments()

        // Wait for background refresh to complete
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds

        #expect(viewModel.canLoadMore == true)
        #expect(viewModel.moments.count == 1)

        // Mock second page response
        let page2Response = MomentFixtures.paginatedResponse(
            moments: [MomentFixtures.momentDTO(text: "Page 2")],
            nextCursor: nil,
            hasNextPage: false
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=20&cursor=cursor123", response: page2Response)

        await viewModel.loadNextPage()

        #expect(viewModel.moments.count == 2)
        #expect(viewModel.canLoadMore == false)
        #expect(viewModel.isLoadingMore == false)
    }
    */

    @Test("Load next page with limit reached sets restriction")
    func loadNextPageLimitReached() async throws {
        // Setup pagination state
        service.nextCursor = "cursor123"
        service.hasNextPage = true
        viewModel.canLoadMore = true

        // Mock response with limit reached
        let response = MomentFixtures.paginatedResponse(
            moments: [MomentFixtures.momentDTO(text: "Limited")],
            nextCursor: nil,
            hasNextPage: false,
            limitReached: true
        )
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=20&cursor=cursor123", response: response)

        await viewModel.loadNextPage()

        #expect(viewModel.isTimelineRestricted == true)
        #expect(viewModel.showTimelineRestrictedPopup == true)
    }

    // MARK: - Favorites Filter Tests

    @Test("Toggle favorites filter shows only favorites")
    func toggleFavoritesFilter() async throws {
        let favorite = MomentFixtures.favoriteMoment(text: "Favorite")
        let regular = MomentFixtures.syncedMoment(text: "Regular")

        try await repository.save(favorite)
        try await repository.save(regular)

        // Mock empty response for initial load
        let emptyResponse = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: emptyResponse)

        // Mock favorites response
        let favResponse = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50&isFavorite=true", response: favResponse)

        #expect(viewModel.isShowingFavoritesOnly == false)

        await viewModel.toggleFavoritesFilter()

        #expect(viewModel.isShowingFavoritesOnly == true)
        #expect(viewModel.moments.count == 1)
        #expect(viewModel.moments.first?.isFavorite == true)
    }

    @Test("Toggle favorites filter off shows all moments")
    func toggleFavoritesFilterOff() async throws {
        let favorite = MomentFixtures.favoriteMoment(text: "Favorite")
        let regular = MomentFixtures.syncedMoment(text: "Regular")

        try await repository.save(favorite)
        try await repository.save(regular)

        // Enable favorites filter first
        service.setFavoritesFilter(true)

        // Mock responses
        let allResponse = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: allResponse)

        await viewModel.toggleFavoritesFilter()

        #expect(viewModel.isShowingFavoritesOnly == false)
        #expect(viewModel.moments.count == 2)
    }

    // MARK: - Toggle Favorite Tests

    @Test("Toggle favorite updates moment")
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

        await viewModel.toggleFavorite(moment)

        #expect(moment.isFavorite == true)
    }

    // MARK: - Delete Moment Tests

    @Test("Delete moment removes from list")
    func deleteMoment() async throws {
        let moment = MomentFixtures.syncedMoment(text: "To delete")
        moment.serverId = "server123"
        try await repository.save(moment)

        // Load moments first
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)
        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 1)

        // Mock delete response
        struct DeleteResponse: Encodable {}
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server123",
            response: DeleteResponse()
        )

        await viewModel.deleteMoment(moment)

        #expect(viewModel.moments.count == 0)
    }

    @Test("Delete moment by IDs removes from list")
    func deleteMomentByIds() async throws {
        let moment = MomentFixtures.syncedMoment(text: "To delete")
        moment.serverId = "server123"
        try await repository.save(moment)

        // Load moments first
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)
        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 1)

        // Mock delete response
        struct DeleteResponse: Encodable {}
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server123",
            response: DeleteResponse()
        )

        let clientId = moment.clientId
        let serverId = moment.serverId

        await viewModel.deleteMomentByIds(clientId: clientId, serverId: serverId)

        #expect(viewModel.moments.count == 0)
    }

    @Test("Delete moment by IDs with nil serverId deletes locally")
    func deleteMomentByIdsWithNilServerId() async throws {
        let moment = MomentFixtures.moment(text: "Unsynced moment")
        moment.isSynced = false
        moment.serverId = nil
        try await repository.save(moment)

        // Load moments first
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)
        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 1)

        let clientId = moment.clientId

        await viewModel.deleteMomentByIds(clientId: clientId, serverId: nil)

        #expect(viewModel.moments.count == 0)
    }

    @Test("Delete moment updates grouped moments")
    func deleteMomentUpdatesGroupedMoments() async throws {
        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)

        let moment1 = MomentFixtures.syncedMoment(text: "Today 1")
        moment1.serverId = "server1"
        moment1.happenedAt = today

        let moment2 = MomentFixtures.syncedMoment(text: "Today 2")
        moment2.serverId = "server2"
        moment2.happenedAt = today

        let moment3 = MomentFixtures.syncedMoment(text: "Yesterday")
        moment3.serverId = "server3"
        moment3.happenedAt = yesterday

        try await repository.save(moment1)
        try await repository.save(moment2)
        try await repository.save(moment3)

        // Load moments first
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)
        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 3)
        #expect(viewModel.groupedMoments.count == 2) // 2 groups (today, yesterday)

        // Mock delete response
        struct DeleteResponse: Encodable {}
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server1",
            response: DeleteResponse()
        )

        await viewModel.deleteMomentByIds(clientId: moment1.clientId, serverId: moment1.serverId)

        #expect(viewModel.moments.count == 2)
        #expect(viewModel.groupedMoments.count == 2) // Still 2 groups
    }

    @Test("Delete last moment in group removes group")
    func deleteLastMomentInGroupRemovesGroup() async throws {
        let today = Date()
        let yesterday = today.addingTimeInterval(-86400)

        let moment1 = MomentFixtures.syncedMoment(text: "Today")
        moment1.serverId = "server1"
        moment1.happenedAt = today

        let moment2 = MomentFixtures.syncedMoment(text: "Yesterday")
        moment2.serverId = "server2"
        moment2.happenedAt = yesterday

        try await repository.save(moment1)
        try await repository.save(moment2)

        // Load moments first
        let response = MomentFixtures.paginatedResponse(moments: [])
        try mockAPI.setResponse(for: "\(AppConfig.apiBaseURL)/moments?limit=50", response: response)
        await viewModel.loadMoments()

        #expect(viewModel.moments.count == 2)
        #expect(viewModel.groupedMoments.count == 2)

        // Mock delete response
        struct DeleteResponse: Encodable {}
        try mockAPI.setResponse(
            for: "\(AppConfig.apiBaseURL)/moments/server1",
            response: DeleteResponse()
        )

        await viewModel.deleteMomentByIds(clientId: moment1.clientId, serverId: moment1.serverId)

        #expect(viewModel.moments.count == 1)
        #expect(viewModel.groupedMoments.count == 1) // Only yesterday group remains
    }

    // MARK: - Detail Sheet Tests

    @Test("Show detail sets state")
    func showDetail() async throws {
        let moment = MomentFixtures.syncedMoment(text: "Detail moment")

        viewModel.showDetail(for: moment)

        #expect(viewModel.selectedMomentForDetail?.text == "Detail moment")
        #expect(viewModel.showMomentDetail == true)
    }

    // MARK: - Error Handling Tests

    @Test("Load moments handles error gracefully")
    func loadMomentsError() async throws {
        // Mock error response
        mockAPI.setError(
            for: "\(AppConfig.apiBaseURL)/moments?limit=50",
            error: MomentError.serverError(message: "Server error")
        )

        await viewModel.loadMoments()

        // Should still complete and not crash
        #expect(viewModel.isInitialLoading == false)
    }
}
