import Foundation
import SwiftData

// MARK: - Moment Repository Protocol
// Abstraction layer for moment data access
// Enables testability and separates SwiftData implementation details

protocol MomentRepository {
    /// Save a new moment to storage
    func save(_ moment: Moment) async throws

    /// Fetch all moments sorted by a descriptor
    func fetchAll(sortedBy: SortDescriptor<Moment>) async throws -> [Moment]

    /// Delete a moment from storage
    func delete(_ moment: Moment) async throws

    /// Update an existing moment
    func update(_ moment: Moment) async throws

    /// Fetch moments that haven't been synced to server yet
    func fetchUnsyncedMoments() async throws -> [Moment]

    /// Find a moment by its client ID
    func fetch(clientId: UUID) async throws -> Moment?

    /// Find a moment by its server ID
    func fetch(serverId: String) async throws -> Moment?

    /// Delete all moments (for testing/dev purposes)
    func deleteAll() async throws

    /// Fetch moments filtered by a specific tag
    func fetchByTag(_ tag: String) async throws -> [Moment]
}
