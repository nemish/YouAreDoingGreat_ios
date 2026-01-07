# You Are Doing Great - iOS App

An emotional-wellness app for logging daily wins with instant encouragement.

## Overview

**You Are Doing Great** helps users capture and celebrate their daily achievements, no matter how small. The app provides instant encouragement through offline praise and AI-generated affirmations.

### Core Features

- **Offline-First Architecture**: Create moments instantly, sync in background
- **Instant Feedback**: Offline praise shows immediately, AI praise updates smoothly
- **Timeline View**: Browse your moments organized by date
- **Favorites**: Mark and filter your favorite moments
- **Journey View**: Visual timeline of your achievements
- **Premium Features**: Unlimited moments and full timeline access via subscription

## Tech Stack

- **Platform**: iOS 17+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Architecture**: MVVM
- **Data Persistence**: SwiftData
- **Networking**: URLSession with async/await
- **Subscriptions**: RevenueCat
- **Testing**: Swift Testing + XCTest

## Project Structure

```
YouAreDoingGreat/
├── App/                    # Entry point, DI container
├── Core/                   # Models, Networking, Persistence, Extensions
│   ├── Models/            # SwiftData models
│   ├── Networking/        # API client, endpoints, models
│   ├── Services/          # System services (Keychain, UserID)
│   └── Utilities/         # Date formatters, helpers
├── Features/               # Feature modules
│   ├── Home/              # Home screen
│   ├── LogMoment/         # Moment creation
│   ├── Praise/            # Praise display
│   ├── MomentsList/       # Moments list and detail
│   ├── Journey/           # Timeline view
│   ├── Profile/           # User profile and settings
│   └── Paywall/           # Subscription screen
├── Services/               # Business logic services
│   ├── MomentService.swift      # Moment CRUD and sync
│   ├── SyncService.swift        # Background sync
│   └── SubscriptionService.swift # RevenueCat integration
├── Repositories/           # Data access layer
│   ├── MomentRepository.swift   # Protocol
│   └── SwiftDataMomentRepository.swift # Implementation
├── Navigation/             # Tab navigation
├── UI/                     # Shared UI components
│   ├── Components/        # Reusable views
│   ├── Modifiers/         # View modifiers
│   └── Theme/             # Colors, fonts, styles
└── Resources/              # Assets, fonts, data files
```

## Getting Started

### Prerequisites

- Xcode 15.2 or later
- macOS Sonoma (14.0) or later
- iOS 17.0+ device or simulator

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/you-are-doing-great-ios.git
   cd you-are-doing-great-ios/YouAreDoingGreat_ios
   ```

2. Open the project:
   ```bash
   open YouAreDoingGreat.xcodeproj
   ```

3. Build and run:
   - Select the `YouAreDoingGreat` scheme
   - Choose an iPhone simulator or device
   - Press `Cmd+R` to build and run

### Configuration

The app uses the following configuration (in `Core/AppConfig.swift`):

- **API Base URL**: `https://1test1.xyz/api/v1` (debug), production URL for release
- **RevenueCat API Key**: Configured for sandbox (debug) and production
- **App Token**: Required for API authentication

## Testing

### Test Coverage

The app has comprehensive test coverage across unit, integration, and UI tests:

- **Unit Tests**: ViewModels, Services, Repositories, Network layer
- **Integration Tests**: Offline-first sync flow, pagination, filtering
- **UI Tests**: Critical user flows (coming soon)

**Coverage Target**: 70%+ for business logic layer

### Running Tests

#### Via Xcode

1. Open the project in Xcode
2. Select the `YouAreDoingGreat` scheme
3. Press `Cmd+U` to run all tests
4. View results in the Test Navigator (`Cmd+6`)

#### Via Command Line

```bash
# Run all tests
xcodebuild test \
  -project YouAreDoingGreat.xcodeproj \
  -scheme YouAreDoingGreat \
  -destination 'platform=iOS Simulator,name=iPhone 15'

# Run with code coverage
xcodebuild test \
  -project YouAreDoingGreat.xcodeproj \
  -scheme YouAreDoingGreat \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult
```

### Test Structure

```
YouAreDoingGreatTests/
├── Helpers/                      # Test utilities
│   ├── MockAPIClient.swift      # Mock network layer
│   ├── TestContainer.swift      # In-memory SwiftData
│   └── MomentFixtures.swift     # Test data factories
├── ViewModels/                   # ViewModel tests
│   └── MomentsListViewModelTests.swift
├── Services/                     # Service tests
│   └── MomentServiceTests.swift
├── Repositories/                 # Repository tests
│   └── MomentRepositoryTests.swift
├── Network/                      # Network layer tests
└── Integration/                  # Integration tests
    └── OfflineFirstFlowTests.swift
```

### Writing Tests

The project uses **Swift Testing** framework for modern, concise test syntax:

```swift
import Testing
import SwiftData
@testable import YouAreDoingGreat

@Suite("My Feature Tests")
@MainActor
struct MyFeatureTests {
    var service: MomentService!
    var repository: MomentRepository!

    init() async throws {
        let context = try TestContainer.makeInMemoryContext()
        repository = SwiftDataMomentRepository(modelContext: context)
        service = MomentService(apiClient: MockAPIClient(), repository: repository)
    }

    @Test("Test description")
    func testSomething() async throws {
        // Arrange
        let moment = MomentFixtures.syncedMoment(text: "Test")

        // Act
        try await repository.save(moment)

        // Assert
        #expect(moment.isSynced == true)
    }
}
```

### Key Testing Patterns

1. **In-Memory SwiftData**: All tests use `TestContainer.makeInMemoryContext()` for isolated, fast tests
2. **Mock API Client**: Network responses are controlled via `MockAPIClient`
3. **Fixtures**: Use `MomentFixtures` for consistent test data
4. **Async/Await**: All tests use native Swift concurrency
5. **MainActor Isolation**: ViewModels and services are tested on `@MainActor`

### CI/CD

Tests run automatically on every pull request via GitHub Actions:

```yaml
# .github/workflows/tests.yml
- Runs on macOS 14 with Xcode 15.2
- Tests on iPhone 15 simulator (iOS 17.2)
- Generates code coverage reports
- Uploads test results as artifacts
```

**Note**: macOS runners consume GitHub Actions minutes 10x faster than Linux runners.

## Architecture

### Offline-First Data Flow

```
User Action
    ↓
ViewModel (UI State)
    ↓
Service (Business Logic)
    ↓
Repository (Data Access)
    ↓
SwiftData (Local Storage) ←→ APIClient (Network)
```

1. **Create Locally**: Moments are created with client UUID and offline praise
2. **Show Immediately**: User sees moment instantly (offline-first)
3. **Background Sync**: Service syncs to server in background
4. **AI Enrichment**: Server adds AI praise, tags, action
5. **Update UI**: Praise fades in smoothly when response arrives

### Key Principles

- **Minimal Friction**: 1-2 taps to log a moment
- **Offline-First**: Never block user on network
- **Instant Feedback**: Offline praise shows immediately
- **Smooth Updates**: AI praise fades in, no jarring changes
- **Warm & Supportive**: Zero shame, zero pressure

## API Integration

See `CLAUDE.md` and `API_SCHEMA.json` for complete API documentation.

**Base URL**: `http://localhost:3000/api/v1` (dev) or production URL

**Authentication**:
- `x-user-id` header for user identification
- `x-app-token-code` header for API access

**Key Endpoints**:
- `GET /moments` - Paginated moments list
- `POST /moments` - Create new moment
- `PUT /moments/:id` - Update moment (favorite toggle)
- `DELETE /moments/:id` - Delete moment
- `GET /timeline` - Paginated timeline view
- `GET /user/stats` - User statistics

## Code Standards

- **Naming**: Prefix booleans with `is/has/should`
- **SwiftUI**: Use `@ViewBuilder` for conditional views
- **Concurrency**: Use async/await (no callbacks)
- **Logging**: Use `OSLog` with appropriate categories
- **Error Handling**: Specific error types (no generic `Error`)
- **No Force Unwraps**: Avoid `!` operator
- **Accessibility**: All UI elements have accessibility labels

## Contributing

### Git Workflow

1. Create a branch from `main`: `yadg-<issue-number>-<description>`
2. Make your changes following the code standards
3. Write tests for new functionality
4. Run tests locally: `xcodebuild test ...`
5. Create a pull request with descriptive title
6. Ensure CI tests pass
7. Request review

### Commit Messages

Follow conventional commits:

```
feat: add delete confirmation dialog (YADG-7)
fix: resolve glitchy filter transitions (YADG-5)
docs: update API schema
refactor: simplify subscription loading
test: add offline-first flow tests
```

### Pull Request Template

See `.linear/issue-template.md` for standard issue format:

- **Context**: Why is this change needed?
- **Requirements & Definition of Done**: What needs to be done?
- **Technical**: Implementation details
- **Extra Sources**: Links to designs, docs, related work

## License

[Your License Here]

## Contact

For questions or support, please open an issue on GitHub.
