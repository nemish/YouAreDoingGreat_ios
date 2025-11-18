# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## API Schema Reference

**IMPORTANT**: The complete API schema is stored in `API_SCHEMA.json` (OpenAPI 3.0.3 format).

**Always consult `API_SCHEMA.json` when making API-related decisions**, including:
- Endpoint paths and HTTP methods
- Request/response schemas
- Authentication headers (`x-user-id`)
- Pagination parameters (cursor-based)
- Error response formats
- Data model structures

The API is served from `http://localhost:3000/api/v1` during development. Key endpoints:
- `POST /moments` - Create a new moment (accepts client UUID)
- `GET /moments` - List moments with cursor pagination
- `GET /moments/{id}` - Get specific moment
- `PUT /moments/{id}` - Update moment (favorite status)
- `DELETE /moments/{id}` - Archive moment (soft delete)
- `GET /timeline` - Get day summaries with pagination
- `GET /user/stats` - Get user statistics and streaks
- `GET /user/me` - Get current user profile

## Project Overview

**You Are Doing Great** is a lightweight emotional-wellness iOS app where users log small daily wins, receive instant encouragement, and track their progress over time. The app provides offline praise immediately, followed by AI-enhanced praise from a server API.

**Tech Stack**:
- **Platform**: iOS 17+
- **Framework**: SwiftUI
- **Architecture**: MVVM + Clean Architecture
- **Persistence**: SwiftData for local storage
- **Concurrency**: async/await, actors
- **Networking**: URLSession with Codable models
- **Offline-First**: Client-generated UUIDs, local-first with background sync

### Core Design Principles

1. **Minimal friction**: 1-2 taps for main action
2. **Warm, supportive tone**: Zero shame, zero pressure
3. **Beautiful, calm visual atmosphere**: Cosmic gradient, floating stars
4. **Instant feedback**: Offline praise shows immediately, AI praise updates smoothly
5. **Simple architecture**: Focus on shipping fast with clean, maintainable code

## Common Development Commands

### Building and Running
```bash
# Build the project
xcodebuild -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -configuration Debug build

# Build for release
xcodebuild -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -configuration Release build

# Clean build folder
xcodebuild -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat clean
```

### Testing
```bash
# Run all tests
xcodebuild test -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -destination 'platform=iOS Simulator,name=iPhone 15'

# Run specific test class
xcodebuild test -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -only-testing:YouAreDoingGreatTests/MomentsListViewModelTests

# Run specific test method
xcodebuild test -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -only-testing:YouAreDoingGreatTests/MomentsListViewModelTests/testLoadMoments
```

## Architecture

### MVVM + Clean Architecture

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

### Project Structure

```
YouAreDoingGreat/
├── App/
│   ├── YouAreDoingGreatApp.swift    # App entry point with DI setup
│   └── DependencyContainer.swift     # Dependency injection
│
├── Core/
│   ├── Models/
│   │   ├── Domain/                   # Business logic models
│   │   └── Data/                     # SwiftData @Model entities
│   ├── Networking/
│   │   ├── APIClient.swift           # Base HTTP client
│   │   ├── Endpoints.swift           # API endpoint definitions
│   │   └── NetworkError.swift        # Network error types
│   ├── Persistence/
│   │   └── ModelContainer+Config.swift
│   └── Extensions/
│       ├── Date+Extensions.swift
│       ├── View+Extensions.swift
│       └── Color+Theme.swift
│
├── Features/
│   ├── Home/
│   │   ├── Views/
│   │   │   └── HomeView.swift
│   │   └── ViewModels/
│   │       └── HomeViewModel.swift
│   ├── LogMoment/
│   │   ├── Views/
│   │   │   ├── LogMomentView.swift
│   │   │   └── TimePickerSheet.swift
│   │   └── ViewModels/
│   │       └── LogMomentViewModel.swift
│   ├── Praise/
│   │   ├── Views/
│   │   │   └── PraiseView.swift
│   │   └── ViewModels/
│   │       └── PraiseViewModel.swift
│   ├── MomentsList/
│   │   ├── Views/
│   │   │   ├── MomentsListView.swift
│   │   │   └── MomentRowView.swift
│   │   └── ViewModels/
│   │       └── MomentsListViewModel.swift
│   ├── Journey/
│   │   ├── Views/
│   │   │   ├── JourneyView.swift
│   │   │   └── DaySummaryCard.swift
│   │   └── ViewModels/
│   │       └── JourneyViewModel.swift
│   ├── Paywall/
│   │   ├── Views/
│   │   │   └── PaywallView.swift
│   │   └── ViewModels/
│   │       └── PaywallViewModel.swift
│   └── Settings/
│       ├── Views/
│       │   └── SettingsView.swift
│       └── ViewModels/
│           └── SettingsViewModel.swift
│
├── Services/
│   ├── MomentService.swift           # Core business logic
│   ├── SyncService.swift             # Background sync
│   ├── PraiseService.swift           # Offline praise pool
│   └── AIEnrichmentService.swift     # AI integration
│
├── Repositories/
│   ├── Protocols/
│   │   ├── MomentRepositoryProtocol.swift
│   │   └── UserRepositoryProtocol.swift
│   ├── MomentRepository.swift
│   └── UserRepository.swift
│
├── Navigation/
│   ├── MainTabView.swift             # 3-tab structure
│   └── NavigationState.swift
│
├── UI/
│   ├── Components/
│   │   ├── LoadingView.swift
│   │   ├── ErrorView.swift
│   │   └── PrimaryButton.swift
│   ├── Modifiers/
│   │   └── StarfieldBackground.swift
│   └── Theme/
│       ├── Typography.swift
│       ├── Colors.swift
│       └── AppTheme.swift
│
├── Utilities/
│   ├── Constants.swift
│   ├── Logger.swift
│   └── Validators.swift
│
└── Resources/
    ├── Assets.xcassets
    ├── OfflinePraise.json            # Local praise pool
    └── Localizable.strings
```

### Module Structure

```
App
├── Home              # Landing screen with "I Did a Thing" button
├── LogMoment         # Text entry + time picker for logging moments
├── Praise            # Offline + AI praise display
├── MomentsList       # Chronological list (Tab 2)
├── Journey           # Daily summaries and timeline (Tab 3)
├── Paywall           # Subscription management
└── Settings          # User preferences, privacy, support
```

### Navigation
- **TabView** with 3 tabs: Home, Moments, Journey
- **Modals**: Log Moment sheet, Time Picker bottom sheet, Paywall
- **SafariView**: For Privacy Policy, Terms, Support pages

### State Management
- Use `@Observable` for ViewModels (iOS 17+)
- Use `@MainActor` for UI-related code
- One ViewModel per module: `HomeViewModel`, `LogMomentViewModel`, etc.
- Keep state local to views when possible using `@State`

## Data Models

### SwiftData Model

**Architecture**: Offline-first with client-generated UUIDs. Moments are created locally first, then synced to server for AI enrichment.

**Note**: Model fields align with API schema. See `API_SCHEMA.json` for complete server model definitions.

```swift
@Model
class Moment {
    // Identity
    @Attribute(.unique) var id: UUID  // Client-generated, submitted to server

    // Core fields (synced with server)
    var text: String
    var submittedAt: Date      // When moment was logged
    var happenedAt: Date       // When moment actually happened (submittedAt - timeAgo)
    var tz: String            // User timezone (e.g., "America/New_York")
    var timeAgo: Int?         // Seconds between happenedAt and submittedAt

    // Server-enriched fields (populated after sync)
    var praise: String?       // AI-generated praise from server
    var action: String?       // Normalized action (e.g., "exercise")
    var tags: [String]        // Extracted tags (e.g., ["milestone", "writing"])
    var isFavorite: Bool      // User-marked favorite

    // Local-only fields (not in API schema)
    var isSynced: Bool        // Whether moment has been synced to server
    var offlinePraise: String // Instant offline praise shown before server response
    var syncError: String?    // Error message if sync failed

    init(text: String, submittedAt: Date = Date(), tz: String, timeAgo: Int? = nil) {
        self.id = UUID()
        self.text = text
        self.submittedAt = submittedAt
        self.happenedAt = timeAgo != nil ? submittedAt.addingTimeInterval(-Double(timeAgo!)) : submittedAt
        self.tz = tz
        self.timeAgo = timeAgo
        self.tags = []
        self.isFavorite = false
        self.isSynced = false
        self.offlinePraise = "" // Set from local JSON pool
    }
}
```

**Backend Note**: The API's `CreateMomentRequest` accepts an optional `id` field (UUID string). If provided, the server uses the client UUID; otherwise, it generates its own ID.

## Core User Flow

1. User opens app → sees **Home Screen** with breathing text and "I Did a Thing" button
2. Taps button → **Log Moment Screen** appears
3. User enters what they did, optionally adjusts time
4. Taps "Save this moment" → moment saved locally with client UUID
5. Navigate to **Praise Screen**:
   - Moment card with text and time
   - Offline praise (instant)
   - Background sync to server starts
   - AI praise fades in when available (replaces offline)
6. User can tap "Done" or "View today's moments"

## Key Implementation Details

### Offline Praise
- Store offline praise phrases in `Resources/OfflinePraise.json`
- Display immediately when moment is saved (no network delay)
- Select randomly from pool
- Never show loading states for offline praise

### AI Praise Integration
- POST to `/api/v1/moments` endpoint after moment is saved locally
- Display offline praise while waiting for AI response
- When AI response arrives, fade animation to replace offline praise
- If AI fails, keep offline praise and optionally show subtle error message

### Time Picker
- Default: "Happened just now"
- User can change via bottom sheet with:
  - Numeric input (e.g., 5)
  - Picker: minutes | hours | days
  - "ago" label
  - "Done" and "Set to just now" buttons
- Calculates `timeAgo` in seconds and `happenedAt` date

### Visual Design

#### Color Palette

**All colors are defined in `Assets.xcassets` with light/dark mode variants.**

Access in code: `Color("Primary")` or via Color extensions.

**Primary Colors:**
- **Primary** - Warm amber/gold accent (Light: #E59500, Dark: #FFB84C)
  - Used for: Primary buttons, highlights, key actions
- **Secondary** - Soft purple/lavender (Light: #8A63D2, Dark: #A88BFA)
  - Used for: Supporting elements, secondary actions

**Background Colors:**
- **Background** - Main background (Light: #FAFAFC, Dark: #0F111C deep navy)
  - Used for: Main screen background, base layer
- **BackgroundSecondary** - Cards and elevated surfaces (Light: #FFFFFF, Dark: #191C2A)
  - Used for: Cards, modals, elevated content
- **BackgroundTertiary** - Subtle elevations (Light: #F2F2F7, Dark: #232634)
  - Used for: Input fields, subtle separations

**Text Colors:**
- **TextPrimary** - Main text (Light: #1C1C1E, Dark: #F2F2F7)
  - Used for: Headlines, body text, primary content
- **TextSecondary** - Subtitles and captions (Light: #636366, Dark: #98989D)
  - Used for: Timestamps, descriptions, secondary info
- **TextTertiary** - Placeholders and disabled text (Light: #AEAEB2, Dark: #636366)
  - Used for: Placeholders, disabled states

**Special Purpose:**
- **Star** - Starfield animation (Light: Purple 30% opacity, Dark: White 80% opacity)
  - Used for: Animated background stars
- **Success** - Positive feedback (Light: #34C759, Dark: #30D158)
  - Used for: Success states, moments saved confirmation
- **Error** - Error states (Light: #FF3B30, Dark: #FF453A)
  - Used for: Errors, destructive actions
- **Warning** - Important info (Light: #FF9500, Dark: #FF9F0A)
  - Used for: Warnings, important alerts

**Gradients (defined in code):**
- **CosmicGradient** - Background gradient using BackgroundTertiary → Background
- **ButtonGradient** - Primary button gradient using Primary color variations

#### Animations
- **Starfield animation** - Slow-moving stars in background
- **Breathing text** - Scale + opacity animation
- **Fade transitions** - 0.2–0.35s duration

#### Haptics
- **Light impact** - Primary taps
- **Medium impact** - "Moment saved" confirmation
- **Light tick** - Tab switch

#### Typography
- **SF Rounded** - Primary font for warmth
- **SF Pro** - System font for UI elements

### Error Handling
- Network failures: Keep offline praise, show subtle error message
- Slow AI response: Keep offline praise with animated subtitle
- Always prioritize showing something positive to the user

## Offline-First Sync Strategy

The app uses an offline-first architecture where moments are created locally immediately, then synced to the server in the background for AI enrichment.

### Sync Flow

1. **Create Locally First**
   - User submits moment → save to SwiftData immediately with client-generated UUID
   - Select random offline praise from local JSON pool
   - Show Praise screen instantly (no network delay)
   - Mark `isSynced = false`

2. **Background Sync to Server**
   - POST moment to `/api/v1/moments` endpoint
   - Include client-generated `id` (UUID) in request body
   - Server accepts UUID and returns enriched data (praise, tags, action)

3. **Update with Server Response**
   - Receive AI-generated praise, tags, and action from server
   - Update local moment with server data
   - Fade animation: offline praise → AI praise
   - Mark `isSynced = true`

4. **Handle Sync Failures**
   - Network error: Keep offline praise, show subtle error message
   - Retry failed syncs in background (exponential backoff)
   - Store `syncError` message for debugging
   - User sees positive feedback regardless of sync status

### Sync Service Pattern

```swift
actor SyncService {
    private let repository: MomentRepositoryProtocol
    private let apiClient: APIClientProtocol

    func syncMoment(_ moment: Moment) async throws {
        // Build request with client UUID
        let request = CreateMomentRequest(
            id: moment.id.uuidString,  // Client-generated UUID
            text: moment.text,
            submittedAt: moment.submittedAt,
            tz: moment.tz,
            timeAgo: moment.timeAgo
        )

        // POST to server
        let response = try await apiClient.request(
            .createMoment(request),
            as: CreateMomentResponse.self
        )

        // Update local moment with server enrichment
        await MainActor.run {
            moment.praise = response.item.praise
            moment.tags = response.item.tags ?? []
            moment.action = response.item.action
            moment.isSynced = true
            moment.syncError = nil
        }
    }

    func retryFailedSyncs() async {
        let unsynced = try? await repository.fetchUnsynced()
        for moment in unsynced ?? [] {
            try? await syncMoment(moment)
        }
    }
}
```

### Key Benefits

- **Instant feedback**: User never waits for network
- **Resilient**: Works offline, syncs when connected
- **Simple conflict resolution**: Client UUID prevents duplicate moments
- **Progressive enhancement**: Offline praise → AI praise seamlessly

## Copy and Tone

All copy must be warm, supportive, and encouraging. Examples:

- **Home screen**: "You Are Doing Great" (title), "Tap to log something you did. Big or small, it counts." (subtext)
- **Log Moment**: "Nice — that counts. What did you do?" (title)
- **Praise**: "Nice move, champ." (offline example)
- **Empty states**: "No moments yet… but you're here, so that's one."
- **Journey**: "Tiny steps, day by day." (subtitle)

Never use language that could feel judgmental, pressuring, or shame-inducing.

## v1 Scope

### In Scope
- Home screen
- Log Moment + Time Picker
- Praise screen (offline + AI)
- Moments list (chronological, sectioned by day)
- Journey timeline (daily cards with summaries)
- Settings (subscription, privacy, support)
- Paywall (7-day trial, yearly/monthly plans)
- SwiftData persistence
- AI integration via API
- Minimal onboarding
- Offline praise pool (local JSON)
- Smooth animations and haptics

### Out of Scope (Future Versions)
- Themes / tone selection
- Push notifications
- Social constellation view
- Weekly summaries
- iCloud sync
- Advanced insights

## Swift Coding Standards

### Naming Conventions

```swift
// ✅ DO: Use clear, descriptive names
class MomentListViewModel { }
func fetchUnsyncedMoments() async throws -> [Moment]
let isLoading: Bool
var moments: [Moment]

// ❌ DON'T: Use abbreviations or unclear names
class MmtVM { }
func getUnsync() -> [Moment]
let loading: Bool

// ✅ DO: Use verb phrases for functions, noun phrases for properties
func loadMoments() async
var momentCount: Int

// ✅ DO: Prefix boolean variables with is/has/should
var isLoading: Bool
var hasUnsyncedChanges: Bool
var shouldShowError: Bool
```

### File Organization

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
    private func handleMomentTap(_ moment: Moment) {
        // ...
    }
}

// 8. Extensions (in same file if small, separate if large)
extension MomentsListView {
    private func buildToolbar() -> some ToolbarContent {
        // ...
    }
}
```

### Access Control

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
    var moments: [Moment] = []
    var isLoading = false

    // Private state
    private var syncTask: Task<Void, Never>?
}
```

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
```

### State Management

```swift
// ✅ DO: Use @Observable for ViewModels (iOS 17+)
@Observable
final class MomentsListViewModel {
    var moments: [Moment] = []
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
    @Query(sort: \Moment.createdAt, order: .reverse)
    private var moments: [Moment]

    var body: some View {
        List(moments) { moment in
            MomentRowView(moment: moment)
        }
    }
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

// ✅ DO: Use lazy stacks for long lists
ScrollView {
    LazyVStack {
        ForEach(moments) { moment in
            MomentRowView(moment: moment)
        }
    }
}
```

## SwiftData Best Practices

### ModelContainer Setup

```swift
// ✅ DO: Configure ModelContainer in App
@main
struct YouAreDoingGreatApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                Moment.self,
                User.self
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
        let schema = Schema([Moment.self])
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
        let moment = Moment(text: "Preview moment", tz: "America/New_York")
        context.insert(moment)

        return container
    }
}
```

### Repository Pattern

```swift
// ✅ DO: Encapsulate data access in Repository
protocol MomentRepositoryProtocol {
    func fetchAll() async throws -> [Moment]
    func fetch(id: UUID) async throws -> Moment?
    func create(_ moment: Moment) async throws
    func update(_ moment: Moment) async throws
    func delete(_ moment: Moment) async throws
    func fetchUnsynced() async throws -> [Moment]
    func search(query: String) async throws -> [Moment]
}

final class MomentRepository: MomentRepositoryProtocol {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    func fetchUnsynced() async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.isSynced == false }
        )
        return try modelContext.fetch(descriptor)
    }

    func search(query: String) async throws -> [Moment] {
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { moment in
                moment.text.localizedStandardContains(query)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
```

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

// ✅ DO: Use .task modifier for view lifecycle async work
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
}

// ✅ DO: Use @MainActor for UI-related code
@MainActor
@Observable
final class MomentsListViewModel {
    var moments: [Moment] = []
    var isLoading = false

    private let repository: MomentRepositoryProtocol

    func loadMoments() async {
        // Automatically runs on MainActor
        isLoading = true

        do {
            moments = try await repository.fetchAll()
        } catch {
            showError(error)
        }

        isLoading = false
    }
}
```

### Structured Concurrency

```swift
// ✅ DO: Use async let for parallel operations
func loadDashboard() async throws {
    async let moments = repository.fetchAll()
    async let stats = statsService.calculateStats()

    // Both run in parallel
    self.moments = try await moments
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

// ✅ DO: Cancel tasks in deinit
@Observable
final class MomentsListViewModel {
    private var loadTask: Task<Void, Never>?

    deinit {
        loadTask?.cancel()
    }
}
```

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

        // Add user ID header for authentication
        if let userId = UserDefaults.standard.string(forKey: "userId") {
            request.setValue(userId, forHTTPHeaderField: "x-user-id")
        }

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        return request
    }
}

// ✅ DO: Define endpoints clearly (see API_SCHEMA.json for all endpoints)
enum Endpoint {
    case fetchMoments(cursor: String?, limit: Int)
    case createMoment(CreateMomentRequest)
    case updateMoment(id: UUID, UpdateMomentRequest)
    case deleteMoment(id: UUID)
    case fetchTimeline(cursor: String?, limit: Int)
    case getUserStats

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
        case .fetchTimeline:
            return "/timeline"
        case .getUserStats:
            return "/user/stats"
        }
    }

    var method: HTTPMethod {
        switch self {
        case .fetchMoments, .fetchTimeline, .getUserStats:
            return .get
        case .createMoment:
            return .post
        case .updateMoment:
            return .put
        case .deleteMoment:
            return .delete
        }
    }

    var body: Encodable? {
        switch self {
        case .createMoment(let dto):
            return dto
        case .updateMoment(_, let dto):
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
        let schema = Schema([Moment.self, User.self])
        let configuration = ModelConfiguration(schema: schema)
        self.modelContainer = try! ModelContainer(
            for: schema,
            configurations: [configuration]
        )

        // Initialize API Client
        self.apiClient = APIClient(
            baseURL: URL(string: "http://localhost:3000/api/v1")!
        )
    }

    func makeMomentsListViewModel() -> MomentsListViewModel {
        MomentsListViewModel(
            repository: momentRepository,
            syncService: syncService
        )
    }
}

// ✅ DO: Inject dependencies from App level
@main
struct YouAreDoingGreatApp: App {
    let dependencies = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .modelContainer(dependencies.modelContainer)
                .environment(dependencies)
        }
    }
}
```

## Logging & Debugging

```swift
// ✅ DO: Use OSLog for structured logging
import OSLog

extension Logger {
    static let app = Logger(subsystem: "com.app.youaredoinggreat", category: "app")
    static let sync = Logger(subsystem: "com.app.youaredoinggreat", category: "sync")
    static let network = Logger(subsystem: "com.app.youaredoinggreat", category: "network")
    static let database = Logger(subsystem: "com.app.youaredoinggreat", category: "database")
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
```

## Performance Guidelines

### Pagination

```swift
// ✅ DO: Implement cursor-based pagination (matches API schema)
@Observable
final class MomentsListViewModel {
    private(set) var moments: [Moment] = []
    private var nextCursor: String?
    private var hasMorePages = true
    private let pageSize = 20

    func loadNextPage() async {
        guard hasMorePages, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await apiClient.request(
                .fetchMoments(cursor: nextCursor, limit: pageSize),
                as: PaginatedMomentsResponse.self
            )

            moments.append(contentsOf: response.data)
            nextCursor = response.nextCursor
            hasMorePages = response.hasNextPage
        } catch {
            showError(error)
        }
    }
}

// Usage in List
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
```

## Security Best Practices

```swift
// ✅ DO: Store sensitive data in Keychain
import Security

actor KeychainService {
    func save(userId: String, for key: String) throws {
        let data = userId.data(using: .utf8)!

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
              let userId = String(data: data, encoding: .utf8) else {
            throw KeychainError.notFound
        }

        return userId
    }
}

// ✅ DO: Validate all user inputs
struct MomentValidator {
    static let maxLength = 1000

    func validate(content: String) throws {
        let sanitized = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !sanitized.isEmpty else {
            throw MomentError.contentEmpty
        }

        guard sanitized.count <= Self.maxLength else {
            throw MomentError.contentTooLong(maxLength: Self.maxLength)
        }
    }
}
```

## Accessibility

```swift
// ✅ DO: Add accessibility labels
struct MomentRowView: View {
    let moment: Moment

    var body: some View {
        VStack(alignment: .leading) {
            Text(moment.text)
            Text(moment.createdAt, style: .relative)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Moment: \(moment.text)")
        .accessibilityHint("Created \(moment.createdAt.formatted(.relative(presentation: .named)))")
    }
}

// ✅ DO: Support Dynamic Type
Text(moment.text)
    .font(.body)
    .lineLimit(nil)
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

// ✅ DO: Add semantic accessibility traits
Button("Delete") {
    deleteMoment()
}
.accessibilityLabel("Delete moment")
.accessibilityAddTraits(.isDestructive)
```

## Testing

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
            Moment(text: "Test 1", tz: "UTC"),
            Moment(text: "Test 2", tz: "UTC")
        ]
        mockRepository.momentsToReturn = expectedMoments

        // When
        await sut.loadMoments()

        // Then
        XCTAssertEqual(sut.moments.count, 2)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }
}

// ✅ DO: Create mock implementations
final class MockMomentRepository: MomentRepositoryProtocol {
    var momentsToReturn: [Moment] = []
    var shouldThrowError = false

    func fetchAll() async throws -> [Moment] {
        if shouldThrowError {
            throw NSError(domain: "Test", code: -1)
        }
        return momentsToReturn
    }

    // ... implement other protocol methods
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
        Moment(text: "First moment", tz: "UTC"),
        Moment(text: "Second moment", tz: "UTC")
    ]

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
- [ ] Warm, supportive copy (no judgment/pressure)
- [ ] Client UUIDs used for offline-first sync
- [ ] Offline praise shown immediately
- [ ] API schema consulted (API_SCHEMA.json)

## Important Notes

- **No Xcode Workspace**: This is a simple Xcode project, not a workspace
- **iOS 17+ Target**: Use modern SwiftUI and SwiftData features
- **No third-party dependencies initially**: Keep it simple for v1
- **Server API**: Node.js backend at `http://localhost:3000/api/v1`
- **Privacy**: Include crisis disclaimer in Settings; this is not a crisis intervention app
- **Offline-First**: Always create locally first, sync in background
- **Client UUIDs**: Backend accepts client-provided UUIDs in POST requests
- **Dark Mode Only (v1)**: App enforces dark mode via `.preferredColorScheme(.dark)` in `YouAreDoingGreatApp.swift`. All colors in `Assets.xcassets` have both light/dark variants defined for future light mode support, but currently only dark mode is active. To add light mode later: remove the `.preferredColorScheme(.dark)` modifier and adjust light mode color values as needed.
