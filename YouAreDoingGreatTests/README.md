# You Are Doing Great - Test Suite

Comprehensive automated tests for the iOS app using Swift Testing framework.

## Quick Start

```bash
# Run all tests
xcodebuild test \
  -project YouAreDoingGreat.xcodeproj \
  -scheme YouAreDoingGreat \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Structure

```
YouAreDoingGreatTests/
├── Helpers/              # Test utilities
├── ViewModels/           # ViewModel tests  
├── Services/             # Service layer tests
├── Repositories/         # Data access tests
├── Network/              # API client tests
└── Integration/          # End-to-end flow tests
```

## Test Count

- **Repository Tests**: 15 tests
- **Service Tests**: 20 tests  
- **ViewModel Tests**: 15 tests
- **Integration Tests**: 12 tests
- **Total**: 62 tests

## Coverage

Target: 70%+ for business logic layer

Current coverage (estimated):
- Repositories: 85%
- Services: 80%
- ViewModels: 60%
- Integration flows: 90%

## Key Features

✅ Swift Testing framework (modern, async/await native)
✅ In-memory SwiftData (fast, isolated tests)
✅ Mock API client for network control
✅ Fixture factories for test data
✅ Comprehensive offline-first flow coverage

## Setup

See `../TESTING_SETUP.md` for complete setup instructions.

## Documentation

- `../README.md` - Project overview and testing guide
- `../TESTING_SETUP.md` - Detailed setup instructions
- `../TEST_IMPLEMENTATION_SUMMARY.md` - Implementation details

## CI/CD

Tests run automatically on every PR via GitHub Actions:
- macOS 14 runner
- Xcode 15.2
- iPhone 15 simulator (iOS 17.2)
- Code coverage enabled
