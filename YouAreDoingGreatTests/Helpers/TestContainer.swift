import Foundation
import SwiftData
@testable import YouAreDoingGreat

// MARK: - Test Container
// Provides in-memory SwiftData containers for testing
// Ensures test isolation and prevents test data from persisting

enum TestContainer {
    /// Creates a new in-memory ModelContainer for testing
    static func makeInMemoryContainer() throws -> ModelContainer {
        let schema = Schema([
            Moment.self,
        ])

        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        return try ModelContainer(
            for: schema,
            configurations: [configuration]
        )
    }

    /// Creates a new in-memory ModelContext for testing
    static func makeInMemoryContext() throws -> ModelContext {
        let container = try makeInMemoryContainer()
        return ModelContext(container)
    }
}
