# Repository Guidelines

## Project Structure & Module Organization
- Primary app code lives in `YouAreDoingGreat/`. `YouAreDoingGreatApp.swift` and `ContentView.swift` wire up navigation and global state.
- Feature slices sit under `Features/` (e.g., `Home`, `Praise`, `LogMoment`, `MomentsList`, `Paywall`, `Onboarding`) with views, view models, and helpers grouped per folder.
- Shared domain and utilities are under `Core/` (`Networking`, `Models`, `Services`, `Extensions`) and app-level config in `Core/AppConfig.swift`.
- UI primitives live in `UI/Components` and reusable view modifiers in `UI/Modifiers`.
- Assets and fonts are in `Assets.xcassets/` and `Resources/Fonts/`; keep new media there and reference via asset catalogs.

## Build, Test, and Development Commands
- Open in Xcode via `open YouAreDoingGreat.xcodeproj` and select the `YouAreDoingGreat` scheme.
- CLI build: `xcodebuild -scheme YouAreDoingGreat -destination 'platform=iOS Simulator,name=iPhone 15' build`.
- Run tests (once added): `xcodebuild -scheme YouAreDoingGreat -destination 'platform=iOS Simulator,name=iPhone 15' test`.
- Previews: use Xcode canvas; ensure targets compile for iOS 17+ to keep SwiftData and SwiftUI features working.

## Coding Style & Naming Conventions
- SwiftUI-first codebase; prefer value types and `Observable` models where possible. Use `// MARK:` to organize extensions and sections.
- Indent with 4 spaces; wrap long lines for readability. Keep view modifiers minimal and refactor into `UI/Modifiers` or small `View` helpers.
- Types/structs/enums use `PascalCase`; methods, properties, and bindings use `camelCase`. Name assets descriptively (e.g., `paywallBg` instead of numeric suffixes).
- Keep network config in `Core/AppConfig.swift`; do not hardcode secrets or user IDs in features.

## Testing Guidelines
- Add new XCTest targets under `YouAreDoingGreatTests/` (not yet present). Name files after the subject, e.g., `PraiseViewModelTests.swift`.
- Favor deterministic tests: inject mock clients for `DefaultAPIClient` and avoid hitting `AppConfig.apiBaseURL` in test runs.
- Include snapshot or UI tests for feature flows with stable IDs; prefer descriptive test names (`test_whenSyncFails_showsRetryState`).

## Commit & Pull Request Guidelines
- Follow the existing conventional commit style (`feat:`, `fix:`, `chore:`, `refactor:`, etc.) as seen in git history.
- PRs should describe the change, mention affected features, and link issues/figma specs if applicable. Include before/after screenshots for UI-facing tweaks.
- Note any API/config changes (especially to `AppConfig`), required migrations, and how to reproduce or verify the change locally.

## Security & Configuration Tips
- Base URLs and headers live in `Core/AppConfig.swift`; keep production values out of debug builds and avoid committing real credentials.
- Prefer dependency injection for tokens/IDs; do not log sensitive payloads in `DefaultAPIClient` debug statements.
- When adding new endpoints, centralize paths and headers in `AppConfig` and keep retries/timeouts consistent with existing constants.
