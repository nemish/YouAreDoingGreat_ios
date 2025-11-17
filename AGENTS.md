# iOS SwiftUI Development Specification

## Project Overview

This specification defines the architecture, patterns, and coding standards for building a moments-based iOS application using SwiftUI, SwiftData, and modern Swift concurrency.

**App Purpose**: Users create and manage moments (notes) with local storage via SwiftData and server synchronization for data enrichment.

**Tech Stack**:

- SwiftUI for UI
- SwiftData for local persistence
- Swift Concurrency (async/await, actors)
- MVVM + Clean Architecture
- Modern iOS (iOS 17+)

---

## Architecture Principles

### Core Architecture: MVVM + Clean Architecture

```
┌─────────────┐
│    Views    │ ← SwiftUI Views (declarative UI)
└──────┬──────┘
       │
┌──────▼──────┐
│ ViewModels  │ ← @Observable classes (presentation logic)
└──────┬──────┘
       │
┌──────▼──────┐
│  Services   │ ← Business logic, orchestration
└──────┬──────┘
       │
┌──────▼──────┐
│Repositories │ ← Data access abstraction
└──────┬──────┘
       │
┌──────▼──────┐
│ Data Layer  │ ← SwiftData, Network, Cache
└─────────────┘
```

### Layer Responsibilities

1. **Views**: Pure UI, no business logic, delegate all actions to ViewModels
2. **ViewModels**: Presentation logic, state management, coordinate services
3. **Services**: Business logic, orchestration between multiple repositories
4. **Repositories**: Single source of truth for data operations, abstract data sources
5. **Data Layer**: SwiftData models, API clients, local storage

---

## Project Structure

```
MomentsApp/
├── App/
│   ├── MomentsApp.swift              # App entry point with DI setup
│   ├── AppConfiguration.swift         # Environment configs
│   └── DependencyContainer.swift      # Dependency injection
│
├── Core/
│   ├── Models/
│   │   ├── Domain/
│   │   │   ├── Moment.swift          # Domain model (business logic)
│   │   │   └── User.swift
│   │   └── Data/
│   │       ├── MomentEntity.swift    # SwiftData @Model
│   │       └── UserEntity.swift
│   │
│   ├── Networking/
│   │   ├── APIClient.swift           # Base HTTP client
│   │   ├── Endpoints.swift           # API endpoint definitions
│   │   ├── NetworkError.swift        # Network error types
│   │   └── RequestBuilder.swift      # URL request construction
│   │
│   ├── Persistence/
│   │   ├── SwiftDataManager.swift    # ModelContext management
│   │   ├── ModelContainer+Config.swift
│   │   └── MigrationPlan.swift       # Data migrations
│   │
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── View+Extensions.swift
│       ├── Color+Theme.swift
│       └── String+Validation.swift
│
├── Features/
│   ├── MomentsList/
│   │   ├── Views/
│   │   │   ├── MomentsListView.swift
│   │   │   ├── MomentRowView.swift
│   │   │   └── EmptyStateView.swift
│   │   ├── ViewModels/
│   │   │   └── MomentsListViewModel.swift
│   │   └── Models/
│   │       └── MomentListItem.swift   # View-specific model
│   │
│   ├── MomentDetail/
│   │   ├── Views/
│   │   │   ├── MomentDetailView.swift
│   │   │   └── MomentMetadataView.swift
│   │   └── ViewModels/
│   │       └── MomentDetailViewModel.swift
│   │
│   ├── CreateMoment/
│   │   ├── Views/
│   │   │   ├── CreateMomentView.swift
│   │   │   └── MomentEditorView.swift
│   │   └── ViewModels/
│   │       └── CreateMomentViewModel.swift
│   │
│   ├── Profile/
│   │   ├── Views/
│   │   │   └── ProfileView.swift
│   │   └── ViewModels/
│   │       └── ProfileViewModel.swift
│   │
│   └── Settings/
│       ├── Views/
│       │   ├── SettingsView.swift
│       │   └── SettingRowView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── Services/
│   ├── MomentService.swift           # Core business logic
│   ├── SyncService.swift             # Bidirectional sync
│   ├── AuthService.swift             # Authentication
│   ├── EnrichmentService.swift       # Server enrichment
│   └── NotificationService.swift     # Push notifications
│
├── Repositories/
│   ├── Protocols/
│   │   ├── MomentRepositoryProtocol.swift
│   │   └── UserRepositoryProtocol.swift
│   ├── MomentRepository.swift
│   └── UserRepository.swift
│
├── Navigation/
│   ├── AppCoordinator.swift          # Navigation logic
│   ├── MainTabView.swift             # Tab structure
│   ├── Route.swift                   # Route definitions
│   └── NavigationState.swift         # Deep linking state
│
├── UI/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   ├── PrimaryButton.swift
│   │   └── SearchBar.swift
│   ├── Modifiers/
│   │   ├── CardStyle.swift
│   │   └── ShimmerEffect.swift
│   └── Theme/
│       ├── Typography.swift
│       ├── Spacing.swift
│       └── AppTheme.swift
│
├── Utilities/
│   ├── Constants.swift
│   ├── Logger.swift                  # Unified logging
│   ├── Validators.swift              # Input validation
│   └── DateFormatter+Shared.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    └── Configuration.plist
```

---

## Coding Standards

### Swift Style Guide

#### Naming Conventions

```swift
// ✅ DO: Use clear, descriptive names
class MomentListViewModel { }
func fetchUnsyncedMoments() async throws -> [MomentEntity]
let isLoading: Bool
var moments: [MomentEntity]

// ❌ DON'T: Use abbreviations or unclear names
class MmtVM { }
func getUnsync() -> [Moment]
let loading: Bool
var arr: [MomentEntity]

// ✅ DO: Use verb phrases for functions, noun phrases for properties
func loadMoments() async
var momentCount: Int

// ✅ DO: Prefix boolean variables with is/has/should
var isLoading: Bool
var hasUnsyncedChanges: Bool
var shouldShowError: Bool
```

#### File Organization

```swift
// ✅ DO: Organize code in this order
// 1. Imports
import SwiftUI
import SwiftData

// 2. Type definition
struct MomentsListView: View {

    // 3. Properties (grouped by type)
    // - Environment
    @Environment(\.modelContext) private var modelContext

    // - State
    @State private var viewModel: MomentsListViewModel
    @State private var selectedMoment: MomentEntity?

    // - Constants
    private let columns = 2

    // 4. Initializer
    init(viewModel: MomentsListViewModel) {
        self.viewModel = viewModel
    }

    // 5. Body
    var body: some View {
        // Implementation
    }

    // 6. Private computed properties
    private var isListEmpty: Bool {
        viewModel.moments.isEmpty
    }

    // 7. Private methods
    private func handleMomentTap(_ moment: MomentEntity) {
        selectedMoment = moment
    }
}

// 8. Extensions (in same file if small, separate if large)
extension MomentsListView {
    private func buildToolbar() -> some ToolbarContent {
        // ...
    }
}
```

#### Access Control

```swift
// ✅ DO: Use explicit access control
public class APIClient { }           // Public APIs
internal class SyncService { }       // Default, module-internal
private func validateInput() { }     // File-private
private(set) var moments: [Moment]   // Read public, write private

// ✅ DO: Use 'private' for ViewModels and implementation details
@Observable
final class MomentsListViewModel {
    private let repository: MomentRepositoryProtocol
    private let syncService: SyncService

    // Public interface
    var moments: [MomentEntity] = []
    var isLoading = false

    // Private state
    private var syncTask: Task<Void, Never>?
}
```

---

## SwiftUI Best Practices

### View Composition

```swift
// ✅ DO: Break down complex views into smaller components
struct MomentsListView: View {
    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Moments")
                .toolbar { toolbarContent }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewModel.isLoading {
            LoadingView()
        } else if viewModel.moments.isEmpty {
            EmptyStateView()
        } else {
            momentsList
        }
    }

    private var momentsList: some View {
        List(viewModel.moments) { moment in
            MomentRowView(moment: moment)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("Add", systemImage: "plus") {
                viewModel.showCreateMoment()
            }
        }
    }
}

// ❌ DON'T: Put everything in body
struct MomentsListView: View {
    var body: some View {
        NavigationStack {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.moments.isEmpty {
                VStack {
                    Image(systemName: "note.text")
                    Text("No moments yet")
                    // ... 50 more lines
                }
            } else {
                List {
                    // ... complex list logic
                }
            }
        }
        .toolbar {
            // ... toolbar items
        }
    }
}
```

### State Management

```swift
// ✅ DO: Use @Observable for ViewModels (iOS 17+)
@Observable
final class MomentsListViewModel {
    var moments: [MomentEntity] = []
    var isLoading = false
    var errorMessage: String?

    func loadMoments() async {
        isLoading = true
        defer { isLoading = false }

        do {
            moments = try await repository.fetchAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Usage in View
struct MomentsListView: View {
    @State private var viewModel: MomentsListViewModel

    var body: some View {
        // Automatically updates when viewModel properties change
        List(viewModel.moments) { moment in
            MomentRowView(moment: moment)
        }
    }
}

// ✅ DO: Use @Query for SwiftData queries in views
struct MomentsListView: View {
    @Query(sort: \MomentEntity.createdAt, order: .reverse)
    private var moments: [MomentEntity]

    var body: some View {
        List(moments) { moment in
            MomentRowView(moment: moment)
        }
    }
}

// ✅ DO: Keep state local when possible
struct CreateMomentView: View {
    @State private var content: String = ""
    @State private var showingAlert = false

    // Only pass to ViewModel on submit
}

// ❌ DON'T: Use @Published with @Observable
@Observable
class ViewModel {
    @Published var data: String = "" // ❌ Redundant, just use var
    var data: String = ""             // ✅ Correct
}
```

### Performance Optimization

```swift
// ✅ DO: Use @ViewBuilder for conditional views
@ViewBuilder
private func contentView(for state: LoadingState) -> some View {
    switch state {
    case .loading:
        LoadingView()
    case .loaded(let moments):
        MomentsList(moments: moments)
    case .error(let message):
        ErrorView(message: message)
    }
}

// ✅ DO: Use Equatable for List items to avoid unnecessary redraws
struct MomentRowView: View {
    let moment: MomentEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text(moment.content)
            Text(moment.createdAt, style: .relative)
        }
    }
}

// Make model Equatable
extension MomentEntity: Equatable {
    static func == (lhs: MomentEntity, rhs: MomentEntity) -> Bool {
        lhs.id == rhs.id && lhs.updatedAt == rhs.updatedAt
    }
}

// ✅ DO: Use lazy loading for expensive operations
struct MomentDetailView: View {
    let moment: MomentEntity

    @State private var enrichedData: EnrichedMoment?

    var body: some View {
        VStack {
            // Basic info loads immediately
            MomentContentView(moment: moment)

            // Enriched data loads asynchronously
            if let enriched = enrichedData {
                EnrichedContentView(data: enriched)
            }
        }
        .task {
            enrichedData = await loadEnrichedData()
        }
    }
}

// ✅ DO: Use .id() modifier to force view recreation when needed
List(moments) { moment in
    MomentRowView(moment: moment)
        .id(moment.id) // Force recreation on ID change
}
```

---

## SwiftData Best Practices

### Model Definition

```swift
// ✅ DO: Use @Model macro and define relationships clearly
import SwiftData
import Foundation

@Model
final class MomentEntity {
    // Primary key
    @Attribute(.unique) var id: UUID

    // Required properties
    var content: String
    var createdAt: Date
    var updatedAt: Date

    // Sync state
    var isSynced: Bool
    var lastSyncedAt: Date?
    var syncError: String?

    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \TagEntity.moments)
    var tags: [TagEntity]

    // Computed properties (not stored)
    var isRecent: Bool {
        Date().timeIntervalSince(createdAt) < 86400 // 24 hours
    }

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = Date(),
        isSynced: Bool = false
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = createdAt
        self.isSynced = isSynced
        self.tags = []
    }
}

// ✅ DO: Create separate tag model with proper relationships
@Model
final class TagEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var moments: [MomentEntity]

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
        self.moments = []
    }
}

// ❌ DON'T: Store complex computed data
@Model
class BadMoment {
    var content: String
    var formattedDate: String // ❌ Store Date, format in View
    var displayText: String   // ❌ Compute in View/ViewModel
}
```

### ModelContainer Setup

```swift
// ✅ DO: Configure ModelContainer in App
@main
struct MomentsApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                MomentEntity.self,
                TagEntity.self,
                UserEntity.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true
            )

            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            // Setup for CloudKit sync if needed
            // container.cloudKitConfiguration = ...

        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(container)
        }
    }
}

// ✅ DO: For previews, use in-memory container
extension ModelContainer {
    static var preview: ModelContainer {
        let schema = Schema([MomentEntity.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )

        let container = try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        // Seed preview data
        let context = container.mainContext
        let moment = MomentEntity(content: "Preview moment")
        context.insert(moment)

        return container
    }
}
```

### CRUD Operations

```swift
// ✅ DO: Encapsulate data access in Repository
protocol MomentRepositoryProtocol {
    func fetchAll() async throws -> [MomentEntity]
    func fetch(id: UUID) async throws -> MomentEntity?
    func create(_ moment: MomentEntity) async throws
    func update(_ moment: MomentEntity) async throws
    func delete(_ moment: MomentEntity) async throws
    func fetchUnsynced() async throws -> [MomentEntity]
    func search(query: String) async throws -> [MomentEntity]
}

final class MomentRepository: MomentRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [MomentEntity] {
        let descriptor = FetchDescriptor<MomentEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetch(id: UUID) async throws -> MomentEntity? {
        var descriptor = FetchDescriptor<MomentEntity>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    func create(_ moment: MomentEntity) async throws {
        modelContext.insert(moment)
        try modelContext.save()
    }

    func update(_ moment: MomentEntity) async throws {
        moment.updatedAt = Date()
        moment.isSynced = false
        try modelContext.save()
    }

    func delete(_ moment: MomentEntity) async throws {
        modelContext.delete(moment)
        try modelContext.save()
    }

    func fetchUnsynced() async throws -> [MomentEntity] {
        let descriptor = FetchDescriptor<MomentEntity>(
            predicate: #Predicate { $0.isSynced == false }
        )
        return try modelContext.fetch(descriptor)
    }

    func search(query: String) async throws -> [MomentEntity] {
        let descriptor = FetchDescriptor<MomentEntity>(
            predicate: #Predicate { moment in
                moment.content.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}

// ✅ DO: Use @Query in Views for reactive updates
struct MomentsListView: View {
    @Query(
        filter: #Predicate<MomentEntity> { !$0.isSynced },
        sort: \MomentEntity.createdAt,
        order: .reverse
    )
    private var unsyncedMoments: [MomentEntity]

    var body: some View {
        List(unsyncedMoments) { moment in
            MomentRowView(moment: moment)
        }
    }
}
```

---

## Async/Await & Concurrency

### Async Functions

```swift
// ✅ DO: Use async/await for all asynchronous operations
func loadMoments() async {
    isLoading = true
    defer { isLoading = false }

    do {
        moments = try await repository.fetchAll()
    } catch {
        errorMessage = error.localizedDescription
    }
}

// ✅ DO: Use Task for calling async from sync contexts
struct MomentsListView: View {
    var body: some View {
        List(viewModel.moments) { moment in
            MomentRowView(moment: moment)
        }
        .task {
            await viewModel.loadMoments()
        }
        .refreshable {
            await viewModel.syncWithServer()
        }
    }
}

// ✅ DO: Use .task modifier for view lifecycle async work
.task {
    await viewModel.loadInitialData()
}

.task(id: selectedFilter) {
    await viewModel.loadMoments(filter: selectedFilter)
}

// ❌ DON'T: Use DispatchQueue for new code
DispatchQueue.main.async {
    // Old pattern, use Task { @MainActor in ... } instead
}
```

### Actor Isolation

```swift
// ✅ DO: Use actors for thread-safe mutable state
actor SyncService {
    private var syncTask: Task<Void, Error>?
    private var lastSyncDate: Date?

    func sync() async throws {
        // Actor ensures serial execution
        guard syncTask == nil else {
            throw SyncError.syncInProgress
        }

        syncTask = Task {
            try await performSync()
            lastSyncDate = Date()
        }

        try await syncTask?.value
        syncTask = nil
    }

    private func performSync() async throws {
        let unsyncedMoments = try await repository.fetchUnsynced()

        for moment in unsyncedMoments {
            try await apiClient.uploadMoment(moment)
            try await repository.markSynced(moment)
        }
    }
}

// ✅ DO: Use @MainActor for UI-related code
@MainActor
@Observable
final class MomentsListViewModel {
    var moments: [MomentEntity] = []
    var isLoading = false

    private let repository: MomentRepositoryProtocol

    func loadMoments() async {
        // Automatically runs on MainActor
        isLoading = true

        do {
            // Repository calls can be off main thread
            moments = try await repository.fetchAll()
        } catch {
            showError(error)
        }

        isLoading = false
    }
}

// ✅ DO: Use nonisolated for non-UI computation
@MainActor
class ViewModel {
    nonisolated func heavyComputation(data: String) -> String {
        // Runs off main thread
        return data.uppercased()
    }
}
```

### Structured Concurrency

```swift
// ✅ DO: Use async let for parallel operations
func loadDashboard() async throws {
    async let moments = repository.fetchAll()
    async let tags = tagRepository.fetchAll()
    async let stats = statsService.calculateStats()

    // All three run in parallel
    self.moments = try await moments
    self.tags = try await tags
    self.stats = try await stats
}

// ✅ DO: Use TaskGroup for dynamic parallel work
func syncAllMoments() async throws {
    let moments = try await repository.fetchUnsynced()

    try await withThrowingTaskGroup(of: Void.self) { group in
        for moment in moments {
            group.addTask {
                try await self.syncMoment(moment)
            }
        }

        try await group.waitForAll()
    }
}

// ✅ DO: Handle task cancellation
func loadMoments() async throws {
    let moments = try await repository.fetchAll()

    try Task.checkCancellation() // Check if cancelled

    self.moments = moments
}

// ✅ DO: Store and cancel tasks properly
@Observable
final class MomentsListViewModel {
    private var loadTask: Task<Void, Never>?

    func loadMoments() {
        loadTask?.cancel() // Cancel previous load

        loadTask = Task {
            do {
                moments = try await repository.fetchAll()
            } catch {
                if !Task.isCancelled {
                    showError(error)
                }
            }
        }
    }

    deinit {
        loadTask?.cancel()
    }
}
```

---

## Networking

### API Client

```swift
// ✅ DO: Create reusable, protocol-based API client
protocol APIClientProtocol {
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T
}

final class APIClient: APIClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder

    init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = .init()
    ) {
        self.baseURL = baseURL
        self.session = session
        self.decoder = decoder
    }

    func request<T: Decodable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T {
        let request = try buildRequest(for: endpoint)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }

    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        let url = baseURL.appendingPathComponent(endpoint.path)
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Add auth token if available
        if let token = AuthService.shared.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}

// ✅ DO: Define endpoints clearly
enum Endpoint {
    case fetchMoments
    case createMoment(MomentDTO)
    case updateMoment(id: UUID, MomentDTO)
    case deleteMoment(id: UUID)
    case enrichMoment(id: UUID)

    var path: String {
        switch self {
        case .fetchMoments:
            return "/moments"
        case .createMoment:
            return "/moments"
        case .updateMoment(let id, _):
            return "/moments/\(id.uuidString)"
        case .deleteMoment(let id):
            return "/moments/\(id.uuidString)"
        case .enrichMoment(let id):
            return "/moments/\(id.uuidString)/enrich"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchMoments:
            return .get
        case .createMoment:
            return .post
        case .updateMoment:
            return .put
        case .deleteMoment:
            return .delete
        case .enrichMoment:
            return .post
        }
    }

    var body: Encodable? {
        switch self {
        case .createMoment(let dto), .updateMoment(_, let dto):
            return dto
        default:
            return nil
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
```

### Error Handling

```swift
// ✅ DO: Define clear error types
enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)
    case noInternetConnection
    case timeout
    case unauthorized

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL is invalid"
        case .invalidResponse:
            return "Invalid response from server"
        case .statusCode(let code):
            return "Server returned status code \(code)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noInternetConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Unauthorized. Please log in again"
        }
    }
}

enum SyncError: LocalizedError {
    case syncInProgress
    case noUnsyncedMoments
    case partialSync(failed: Int, total: Int)

    var errorDescription: String? {
        switch self {
        case .syncInProgress:
            return "Sync already in progress"
        case .noUnsyncedMoments:
            return "No moments to sync"
        case .partialSync(let failed, let total):
            return "Synced \(total - failed) of \(total) moments"
        }
    }
}

// ✅ DO: Handle errors gracefully in ViewModels
@Observable
final class MomentsListViewModel {
    var errorMessage: String?
    var showingError = false

    func loadMoments() async {
        do {
            moments = try await repository.fetchAll()
        } catch {
            showError(error)
        }
    }

    private func showError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
}

// Usage in View
.alert("Error", isPresented: $viewModel.showingError) {
    Button("OK") { }
} message: {
    Text(viewModel.errorMessage ?? "Unknown error")
}
```

---

## Sync Service Pattern

```swift
// ✅ DO: Implement robust sync service
actor SyncService {
    enum SyncState {
        case idle
        case syncing
        case error(Error)
    }

    private let repository: MomentRepositoryProtocol
    private let apiClient: APIClientProtocol
    private let logger: Logger

    private(set) var state: SyncState = .idle
    private var syncTask: Task<Void, Never>?

    init(
        repository: MomentRepositoryProtocol,
        apiClient: APIClientProtocol,
        logger: Logger = .init(subsystem: "com.app.moments", category: "sync")
    ) {
        self.repository = repository
        self.apiClient = apiClient
        self.logger = logger
    }

    func startSync() async {
        guard case .idle = state else {
            logger.warning("Sync already in progress")
            return
        }

        state = .syncing

        do {
            // 1. Upload local changes
            try await uploadLocalChanges()

            // 2. Download server changes
            try await downloadServerChanges()

            // 3. Resolve conflicts
            try await resolveConflicts()

            state = .idle
            logger.info("Sync completed successfully")

        } catch {
            state = .error(error)
            logger.error("Sync failed: \(error)")
        }
    }

    private func uploadLocalChanges() async throws {
        let unsyncedMoments = try await repository.fetchUnsynced()
        logger.info("Uploading \(unsyncedMoments.count) moments")

        for moment in unsyncedMoments {
            let dto = MomentDTO(from: moment)

            if moment.lastSyncedAt == nil {
                // Create new
                _ = try await apiClient.request(
                    .createMoment(dto),
                    as: MomentResponse.self
                )
            } else {
                // Update existing
                _ = try await apiClient.request(
                    .updateMoment(id: moment.id, dto),
                    as: MomentResponse.self
                )
            }

            try await repository.markSynced(moment)
        }
    }

    private func downloadServerChanges() async throws {
        let response = try await apiClient.request(
            .fetchMoments,
            as: MomentsListResponse.self
        )

        for serverMoment in response.moments {
            if let localMoment = try await repository.fetch(id: serverMoment.id) {
                // Update local if server is newer
                if serverMoment.updatedAt > localMoment.updatedAt {
                    localMoment.content = serverMoment.content
                    localMoment.updatedAt = serverMoment.updatedAt
                    try await repository.update(localMoment)
                }
            } else {
                // Create local copy
                let newMoment = MomentEntity(from: serverMoment)
                try await repository.create(newMoment)
            }
        }
    }

    private func resolveConflicts() async throws {
        // Implement conflict resolution strategy
        // Last-write-wins, or more sophisticated merging
    }
}

// ✅ DO: Schedule background sync
extension SyncService {
    func scheduleBackgroundSync() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.app.moments.sync",
            using: nil
        ) { task in
            Task {
                await self.startSync()
                task.setTaskCompleted(success: self.state == .idle)
            }
        }
    }
}
```

---

## Testing Standards

### Unit Testing

```swift
// ✅ DO: Write unit tests for ViewModels
@MainActor
final class MomentsListViewModelTests: XCTestCase {
    var sut: MomentsListViewModel!
    var mockRepository: MockMomentRepository!
    var mockSyncService: MockSyncService!

    override func setUp() {
        super.setUp()
        mockRepository = MockMomentRepository()
        mockSyncService = MockSyncService()
        sut = MomentsListViewModel(
            repository: mockRepository,
            syncService: mockSyncService
        )
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        mockSyncService = nil
        super.tearDown()
    }

    func testLoadMoments_Success() async {
        // Given
        let expectedMoments = [
            MomentEntity(content: "Test 1"),
            MomentEntity(content: "Test 2")
        ]
        mockRepository.momentsToReturn = expectedMoments

        // When
        await sut.loadMoments()

        // Then
        XCTAssertEqual(sut.moments.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testLoadMoments_Failure() async {
        // Given
        mockRepository.shouldThrowError = true

        // When
        await sut.loadMoments()

        // Then
        XCTAssertTrue(sut.moments.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.errorMessage)
    }
}

// ✅ DO: Create mock implementations
final class MockMomentRepository: MomentRepositoryProtocol {
    var momentsToReturn: [MomentEntity] = []
    var shouldThrowError = false
    var fetchAllCallCount = 0

    func fetchAll() async throws -> [MomentEntity] {
        fetchAllCallCount += 1
        if shouldThrowError {
            throw NSError(domain: "Test", code: -1)
        }
        return momentsToReturn
    }

    func create(_ moment: MomentEntity) async throws {
        momentsToReturn.append(moment)
    }

    // ... implement other protocol methods
}
```

### SwiftUI Testing

```swift
// ✅ DO: Test views with ViewInspector or manual testing
import ViewInspector
import XCTest

final class MomentsListViewTests: XCTestCase {
    func testEmptyState_IsShown_WhenNoMoments() throws {
        // Given
        let viewModel = MomentsListViewModel(
            repository: MockMomentRepository(),
            syncService: MockSyncService()
        )
        viewModel.moments = []

        let view = MomentsListView(viewModel: viewModel)

        // When
        let emptyStateView = try view.inspect().find(EmptyStateView.self)

        // Then
        XCTAssertNotNil(emptyStateView)
    }
}
```

### Preview Providers

```swift
// ✅ DO: Create comprehensive preview providers
#Preview("List - Empty") {
    MomentsListView(
        viewModel: MomentsListViewModel(
            repository: MockMomentRepository(),
            syncService: MockSyncService()
        )
    )
    .modelContainer(ModelContainer.preview)
}

#Preview("List - With Moments") {
    let viewModel = MomentsListViewModel(
        repository: MockMomentRepository(),
        syncService: MockSyncService()
    )
    viewModel.moments = [
        MomentEntity(content: "First moment"),
        MomentEntity(content: "Second moment"),
        MomentEntity(content: "Third moment")
    ]

    return MomentsListView(viewModel: viewModel)
        .modelContainer(ModelContainer.preview)
}

#Preview("List - Loading") {
    let viewModel = MomentsListViewModel(
        repository: MockMomentRepository(),
        syncService: MockSyncService()
    )
    viewModel.isLoading = true

    return MomentsListView(viewModel: viewModel)
        .modelContainer(ModelContainer.preview)
}

#Preview("List - Dark Mode") {
    MomentsListView(
        viewModel: MomentsListViewModel(
            repository: MockMomentRepository(),
            syncService: MockSyncService()
        )
    )
    .preferredColorScheme(.dark)
    .modelContainer(ModelContainer.preview)
}
```

---

## Dependency Injection

```swift
// ✅ DO: Use constructor injection
@Observable
final class MomentsListViewModel {
    private let repository: MomentRepositoryProtocol
    private let syncService: SyncService

    init(
        repository: MomentRepositoryProtocol,
        syncService: SyncService
    ) {
        self.repository = repository
        self.syncService = syncService
    }
}

// ✅ DO: Create a dependency container
final class DependencyContainer {
    // Singletons
    let modelContainer: ModelContainer
    let apiClient: APIClientProtocol

    // Lazy properties
    private(set) lazy var syncService: SyncService = {
        SyncService(
            repository: momentRepository,
            apiClient: apiClient
        )
    }()

    private(set) lazy var momentRepository: MomentRepositoryProtocol = {
        MomentRepository(modelContext: modelContainer.mainContext)
    }()

    init() {
        // Initialize ModelContainer
        let schema = Schema([MomentEntity.self])
        let configuration = ModelConfiguration(schema: schema)
        self.modelContainer = try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        // Initialize API Client
        self.apiClient = APIClient(
            baseURL: URL(string: "https://api.moments.app")!
        )
    }

    func makeMomentsListViewModel() -> MomentsListViewModel {
        MomentsListViewModel(
            repository: momentRepository,
            syncService: syncService
        )
    }

    func makeCreateMomentViewModel() -> CreateMomentViewModel {
        CreateMomentViewModel(
            repository: momentRepository,
            syncService: syncService
        )
    }
}

// ✅ DO: Inject dependencies from App level
@main
struct MomentsApp: App {
    let dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(dependencies.modelContainer)
                .environment(dependencies)
        }
    }
}

// Usage in Views
struct MomentsListView: View {
    @Environment(DependencyContainer.self) private var dependencies
    @State private var viewModel: MomentsListViewModel?

    var body: some View {
        if let viewModel {
            contentView(viewModel: viewModel)
        }
        else {
            ProgressView()
                .task {
                    viewModel = dependencies.makeMomentsListViewModel()
                }
        }
    }

    private func contentView(viewModel: MomentsListViewModel) -> some View {
        List(viewModel.moments) { moment in
            MomentRowView(moment: moment)
        }
    }
}
```

---

## Error Handling Guidelines

```swift
// ✅ DO: Create specific error types per domain
enum MomentError: LocalizedError {
    case contentEmpty
    case contentTooLong(maxLength: Int)
    case invalidFormat
    case notFound(id: UUID)

    var errorDescription: String? {
        switch self {
        case .contentEmpty:
            return "Moment content cannot be empty"
        case .contentTooLong(let maxLength):
            return "Content exceeds maximum length of \(maxLength) characters"
        case .invalidFormat:
            return "Invalid moment format"
        case .notFound(let id):
            return "Moment with ID \(id) not found"
        }
    }
}

// ✅ DO: Handle errors at appropriate levels
@Observable
final class CreateMomentViewModel {
    var content: String = ""
    var errorMessage: String?
    var showingError = false

    private let repository: MomentRepositoryProtocol
    private let validator: MomentValidator

    func createMoment() async {
        do {
            // Validate input
            try validator.validate(content: content)

            // Create moment
            let moment = MomentEntity(content: content)
            try await repository.create(moment)

            // Success - dismiss or navigate

        } catch let error as MomentError {
            // Handle domain-specific errors
            showError(error.localizedDescription)

        } catch {
            // Handle unexpected errors
            showError("Failed to create moment: \(error.localizedDescription)")
        }
    }

    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// ✅ DO: Create validators
struct MomentValidator {
    static let maxLength = 1000

    func validate(content: String) throws {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw MomentError.contentEmpty
        }

        guard content.count <= Self.maxLength else {
            throw MomentError.contentTooLong(maxLength: Self.maxLength)
        }
    }
}
```

---

## Logging & Debugging

```swift
// ✅ DO: Use OSLog for structured logging
import OSLog

extension Logger {
    static let app = Logger(subsystem: "com.app.moments", category: "app")
    static let sync = Logger(subsystem: "com.app.moments", category: "sync")
    static let network = Logger(subsystem: "com.app.moments", category: "network")
    static let database = Logger(subsystem: "com.app.moments", category: "database")
}

// Usage
actor SyncService {
    func startSync() async {
        Logger.sync.info("Starting sync process")

        do {
            try await performSync()
            Logger.sync.info("Sync completed successfully")
        } catch {
            Logger.sync.error("Sync failed: \(error.localizedDescription)")
        }
    }
}

// ✅ DO: Use log levels appropriately
Logger.app.debug("Detailed debugging info")
Logger.app.info("Normal information")
Logger.app.notice("Significant but normal event")
Logger.app.warning("Warning condition")
Logger.app.error("Error condition")
Logger.app.critical("Critical condition")
Logger.app.fault("Fatal error")

// ✅ DO: Log important events
class MomentRepository {
    func create(_ moment: MomentEntity) async throws {
        Logger.database.debug("Creating moment: \(moment.id)")

        modelContext.insert(moment)

        do {
            try modelContext.save()
            Logger.database.info("Moment created successfully: \(moment.id)")
        } catch {
            Logger.database.error("Failed to create moment: \(error)")
            throw error
        }
    }
}
```

---

## Performance Guidelines

### View Performance

```swift
// ✅ DO: Use lazy stacks for long lists
ScrollView {
    LazyVStack {
        ForEach(moments) { moment in
            MomentRowView(moment: moment)
        }
    }
}

// ✅ DO: Implement pagination for large datasets
@Observable
final class MomentsListViewModel {
    private(set) var moments: [MomentEntity] = []
    private var currentPage = 0
    private let pageSize = 20
    private var hasMorePages = true

    func loadNextPage() async {
        guard hasMorePages, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let newMoments = try await repository.fetchPage(
                page: currentPage,
                size: pageSize
            )

            moments.append(contentsOf: newMoments)
            currentPage += 1
            hasMorePages = newMoments.count == pageSize

        } catch {
            showError(error)
        }
    }
}

// Usage
List {
    ForEach(viewModel.moments) { moment in
        MomentRowView(moment: moment)
            .onAppear {
                if moment == viewModel.moments.last {
                    Task {
                        await viewModel.loadNextPage()
                    }
                }
            }
    }
}

// ✅ DO: Cache expensive computations
@Observable
final class MomentDetailViewModel {
    private var enrichedContentCache: [UUID: EnrichedContent] = [:]

    func enrichedContent(for momentId: UUID) async -> EnrichedContent? {
        if let cached = enrichedContentCache[momentId] {
            return cached
        }

        let enriched = await fetchEnrichedContent(momentId)
        enrichedContentCache[momentId] = enriched
        return enriched
    }
}
```

### Memory Management

```swift
// ✅ DO: Use weak self in closures when needed
class SyncService {
    func schedulePeriodicSync() {
        timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task {
                await self?.startSync()
            }
        }
    }
}

// ✅ DO: Cancel tasks in deinit
@Observable
final class MomentsListViewModel {
    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }
}

// ✅ DO: Use @MainActor for UI-bound objects
@MainActor
@Observable
final class MomentsListViewModel {
    // Automatically main-actor isolated
    var moments: [MomentEntity] = []
    var isLoading = false
}
```

---

## Security Best Practices

```swift
// ✅ DO: Store sensitive data in Keychain
import Security

actor KeychainService {
    func save(token: String, for key: String) throws {
        let data = token.data(using: .utf8)!

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed
        }
    }

    func retrieve(for key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }

        return token
    }
}

// ✅ DO: Validate all user inputs
struct MomentValidator {
    func validate(content: String) throws {
        // Remove potentially harmful characters
        let sanitized = content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "<script>", with: "")

        guard !sanitized.isEmpty else {
            throw MomentError.contentEmpty
        }

        guard sanitized.count <= 1000 else {
            throw MomentError.contentTooLong(maxLength: 1000)
        }
    }
}

// ✅ DO: Use HTTPS for all network requests
let apiClient = APIClient(
    baseURL: URL(string: "https://api.moments.app")! // Always HTTPS
)
```

---

## Accessibility

```swift
// ✅ DO: Add accessibility labels
struct MomentRowView: View {
    let moment: MomentEntity

    var body: some View {
        VStack(alignment: .leading) {
            Text(moment.content)
            Text(moment.createdAt, style: .relative)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moment: \(moment.content)")
        .accessibilityHint("Created \(moment.createdAt.formatted(.relative(presentation: .named)))")
    }
}

// ✅ DO: Support Dynamic Type
Text(moment.content)
    .font(.body)
    .lineLimit(nil)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

// ✅ DO: Add semantic accessibility traits
Button("Delete") {
    deleteMoment()
}
.accessibilityLabel("Delete moment")
.accessibilityAddTraits(.isDestructive)

// ✅ DO: Support VoiceOver navigation
List {
    ForEach(moments) { moment in
        MomentRowView(moment: moment)
            .accessibilityIdentifier("moment-\(moment.id)")
    }
}
```

---

## Key Takeaways

1. **Architecture**: Use MVVM with Clean Architecture principles
2. **SwiftUI**: Compose views, use @Observable, leverage @Query
3. **SwiftData**: Repository pattern for data access, proper model design
4. **Concurrency**: async/await everywhere, actors for thread safety
5. **Networking**: Protocol-based API client, proper error handling
6. **Sync**: Robust sync service with conflict resolution
7. **Testing**: Unit tests for logic, SwiftUI previews for UI
8. **DI**: Constructor injection, dependency container
9. **Performance**: Lazy loading, pagination, caching
10. **Security**: Keychain for tokens, input validation, HTTPS

---

## Code Review Checklist

- [ ] Follows naming conventions
- [ ] Proper access control (private, internal, public)
- [ ] ViewModels use @Observable and @MainActor
- [ ] Async functions use async/await (no callbacks)
- [ ] Network calls use APIClient protocol
- [ ] Data access goes through Repository
- [ ] Errors are handled with specific error types
- [ ] Logging uses OSLog with appropriate levels
- [ ] UI updates on MainActor
- [ ] Tasks are cancelled in deinit
- [ ] No force unwraps (!)
- [ ] SwiftData models use @Model correctly
- [ ] Views are decomposed into smaller components
- [ ] Accessibility labels present
- [ ] Preview providers included
- [ ] Unit tests for business logic
- [ ] No hardcoded strings (use Localizable.strings)
- [ ] Sensitive data stored in Keychain
- [ ] Input validation present

---

**Version**: 1.0  
**Last Updated**: 2024  
**Maintained By**: Development Team
