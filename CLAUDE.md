# CLAUDE.md

Always use context7 when I need code generation, setup or configuration steps, or
library/API documentation. This means you should automatically use the Context7 MCP
tools to resolve library id and get library docs without me having to explicitly ask.

## API Schema Reference

**Always consult `API_SCHEMA.json`** for endpoint details, request/response schemas, and data models.

- Base URL: `http://localhost:3000/api/v1`
- Auth: `x-user-id` header
- Pagination: cursor-based

Key endpoints: `/moments` (CRUD), `/timeline`, `/user/stats`, `/user/me`

## Reference Implementation

`youre-doing-great-app_old` (in same parent directory) contains the old React Native implementation. **Reference only** for functionality - never modify files there.

## Project Overview

**You Are Doing Great** - iOS emotional-wellness app for logging daily wins with instant encouragement.

**Stack**: iOS 17+, SwiftUI, MVVM, SwiftData, async/await, URLSession

### Core Principles
- Minimal friction (1-2 taps)
- Warm, supportive tone (zero shame/pressure)
- Instant feedback (offline praise immediately, AI praise updates smoothly)
- Offline-first with background sync

## Commands

```bash
# Build
xcodebuild -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat build

# Test
xcodebuild test -project YouAreDoingGreat.xcodeproj -scheme YouAreDoingGreat -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Architecture

```
Views → ViewModels (@Observable) → Services → Repositories → Data Layer (SwiftData/Network)
```

### Project Structure
```
YouAreDoingGreat/
├── App/                    # Entry point, DI container
├── Core/                   # Models, Networking, Persistence, Extensions
├── Features/               # Home, LogMoment, Praise, MomentsList, Journey, Paywall, Settings
├── Services/               # MomentService, SyncService, PraiseService
├── Repositories/           # Data access abstraction
├── Navigation/             # MainTabView, NavigationState
├── UI/                     # Components, Modifiers, Theme
└── Resources/              # Assets, Fonts, OfflinePraise.json
```

## Data Model

```swift
@Model
class Moment {
    @Attribute(.unique) var id: UUID  // Client-generated
    var text: String
    var submittedAt: Date
    var happenedAt: Date
    var tz: String
    var timeAgo: Int?

    // Server-enriched
    var praise: String?
    var action: String?
    var tags: [String]
    var isFavorite: Bool

    // Local-only
    var isSynced: Bool
    var offlinePraise: String
    var syncError: String?
}
```

## Offline-First Sync

1. Create locally with client UUID → show offline praise instantly
2. POST to `/moments` in background
3. Update with AI praise when response arrives (fade animation)
4. Retry failed syncs with exponential backoff

## Visual Design

**Colors** (in `Assets.xcassets`):
- Primary: Amber/gold, Secondary: Purple/lavender
- Background: Deep navy (#0F111C dark)
- Access via `Color("Primary")` or Color extensions

**Typography** (in `Font+Extensions.swift`):
- GloriaHallelujah: titles (`.appLargeTitle`, `.appTitle`)
- Comfortaa: body (`.appBody`, `.appHeadline`)

**Animations**: Starfield background, breathing text (scale + opacity), 0.2-0.35s fades

**Haptics**: Light (taps), Medium (moment saved), Light tick (tab switch)

**Dark Mode Only (v1)**: Enforced via `.preferredColorScheme(.dark)`

## Key Patterns

### ViewModels
- Use `@Observable` and `@MainActor`
- Constructor injection for dependencies
- Cancel tasks in deinit

### Networking
- Protocol-based `APIClient`
- `x-user-id` header for auth
- Specific error types (`NetworkError`, `MomentError`)

### SwiftData
- Repository pattern for data access
- `@Query` for direct SwiftData queries in views
- In-memory container for previews

### Concurrency
- `async/await` everywhere (no DispatchQueue)
- Actors for thread-safe state
- `async let` for parallel operations

## Code Standards

### Project-Specific Rules
- Prefix booleans: `is/has/should`
- Use `@ViewBuilder` for conditional views
- Logging via `OSLog` (Logger.app, .sync, .network, .database)
- Store sensitive data in Keychain

### Avoid
- Force unwraps (!)
- Hardcoded strings (use Localizable.strings)
- Over-engineering beyond what's requested

## Copy & Tone

Always warm and supportive. Examples:
- "Nice — that counts. What did you do?"
- "No moments yet… but you're here, so that's one."

Never judgmental or pressure-inducing.

## v1 Scope

**In**: Home, LogMoment, Praise, MomentsList, Journey, Settings, Paywall, offline praise, AI integration

**Out**: Themes, notifications, social features, iCloud sync, widgets

## Code Review Checklist

- [ ] ViewModels use `@Observable` + `@MainActor`
- [ ] Async/await (no callbacks)
- [ ] Repository pattern for data access
- [ ] Specific error types
- [ ] Tasks cancelled in deinit
- [ ] No force unwraps
- [ ] Accessibility labels
- [ ] Warm, supportive copy
- [ ] Client UUIDs for offline-first
- [ ] API schema consulted
