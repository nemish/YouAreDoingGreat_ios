//
//  ViewModelFactory.swift
//  YouAreDoingGreat
//
//  Created on 17.11.2025.
//

import Foundation
import SwiftData

// MARK: - ViewModel Factory
// Centralized dependency injection and ViewModel creation
// Keeps views clean and makes testing easier

@MainActor
final class ViewModelFactory {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Moment-related ViewModels
    
    func makeMomentsListViewModel() -> MomentsListViewModel {
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        let apiClient = DefaultAPIClient()
        let service = MomentService(apiClient: apiClient, repository: repository)
        return MomentsListViewModel(momentService: service, repository: repository)
    }
    
    // MARK: - Profile ViewModel
    
    func makeProfileViewModel() -> ProfileViewModel {
        let apiClient = DefaultAPIClient()
        let userService = UserService(apiClient: apiClient)
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        return ProfileViewModel(userService: userService, momentRepository: repository)
    }
    
    // MARK: - Shared Dependencies (for reuse if needed)
    
    func makeMomentRepository() -> MomentRepository {
        SwiftDataMomentRepository(modelContext: modelContext)
    }
    
    func makeAPIClient() -> APIClient {
        DefaultAPIClient()
    }
    
    func makeMomentService() -> MomentService {
        let repository = makeMomentRepository()
        let apiClient = makeAPIClient()
        return MomentService(apiClient: apiClient, repository: repository)
    }

    // MARK: - Journey ViewModel

    func makeJourneyViewModel() -> JourneyViewModel {
        let apiClient = makeAPIClient()
        return JourneyViewModel(apiClient: apiClient)
    }

    // MARK: - Paywall ViewModel

    func makePaywallViewModel() -> PaywallViewModel {
        PaywallViewModel(subscriptionService: SubscriptionService.shared)
    }

    // MARK: - Galaxy ViewModel

    func makeGalaxyViewModel(screenSize: CGSize) -> GalaxyViewModel {
        let repository = SwiftDataMomentRepository(modelContext: modelContext)
        return GalaxyViewModel(repository: repository, screenSize: screenSize)
    }
}

