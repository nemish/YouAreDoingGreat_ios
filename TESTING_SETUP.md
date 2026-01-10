# Test Setup Guide

This guide walks you through adding the test targets to the Xcode project and verifying the test suite works correctly.

## Quick Start

All test files have been created in the `YouAreDoingGreatTests/` directory. You need to add a test target to the Xcode project and include these files.

## Step 1: Create Test Target in Xcode

1. Open `YouAreDoingGreat.xcodeproj` in Xcode
2. Select the project in the Navigator (top-level "YouAreDoingGreat")
3. Click the "+" button at the bottom of the targets list
4. Choose "Unit Testing Bundle" under iOS
5. Name it: `YouAreDoingGreatTests`
6. Host Application: `YouAreDoingGreat`
7. Click "Finish"

## Step 2: Add Test Files to Target

### Option A: Drag and Drop (Recommended)

1. In Finder, navigate to `YouAreDoingGreat_ios/YouAreDoingGreatTests/`
2. In Xcode, right-click on the project and select "Add Files to YouAreDoingGreat..."
3. Select the `YouAreDoingGreatTests` folder
4. **Important**: Check these options:
   - ✅ "Create groups" (not folder references)
   - ✅ "Add to targets: YouAreDoingGreatTests"
   - ❌ Uncheck "Add to targets: YouAreDoingGreat" (only check the test target)
5. Click "Add"

### Option B: Add Files Individually

If you prefer to add files one by one:

1. Right-click on `YouAreDoingGreatTests` group in Xcode
2. Select "Add Files to YouAreDoingGreat..."
3. Navigate to each test file and add it
4. Ensure "Target Membership" is set to `YouAreDoingGreatTests` only

### Files to Add

```
YouAreDoingGreatTests/
├── Helpers/
│   ├── MockAPIClient.swift
│   ├── TestContainer.swift
│   └── MomentFixtures.swift
├── ViewModels/
│   └── MomentsListViewModelTests.swift
├── Services/
│   └── MomentServiceTests.swift
├── Repositories/
│   └── MomentRepositoryTests.swift
└── Integration/
    └── OfflineFirstFlowTests.swift
```

## Step 3: Configure Test Target Settings

1. Select the `YouAreDoingGreatTests` target
2. Go to "Build Settings"
3. Verify these settings:

### Swift Compiler - Language
- **Swift Language Version**: Swift 5

### Linking
- **Other Linker Flags**: (should include) `$(inherited)`

### Search Paths
- **Framework Search Paths**: `$(inherited)`
- **Header Search Paths**: `$(inherited)`

## Step 4: Add @testable Import

The test files already include `@testable import YouAreDoingGreat`, which allows tests to access internal types from the main app.

## Step 5: Enable Code Coverage

1. Select the scheme dropdown → "Edit Scheme..."
2. Select "Test" in the left sidebar
3. Go to "Options" tab
4. Check ✅ "Code Coverage" for: `YouAreDoingGreat`
5. Click "Close"

## Step 6: Run Tests

### Via Xcode

1. Select the `YouAreDoingGreat` scheme
2. Choose a simulator (e.g., iPhone 15)
3. Press `Cmd+U` to run all tests
4. View results in Test Navigator (`Cmd+6`)

### Via Command Line

```bash
xcodebuild test \
  -project YouAreDoingGreat.xcodeproj \
  -scheme YouAreDoingGreat \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -enableCodeCoverage YES
```

## Step 7: Verify Test Results

You should see:

- ✅ **Repository Tests**: ~15 tests passing (CRUD, filtering, unique constraints)
- ✅ **Service Tests**: ~20 tests passing (sync, pagination, favorites)
- ✅ **ViewModel Tests**: ~15 tests passing (loading, refresh, filtering)
- ✅ **Integration Tests**: ~12 tests passing (offline-first flow, conflict resolution)

**Total**: ~62 tests

## Troubleshooting

### Issue: "No such module 'YouAreDoingGreat'"

**Solution**: Ensure the test target has access to the app module:
1. Select `YouAreDoingGreatTests` target
2. Go to "Build Phases"
3. Expand "Dependencies"
4. Click "+" and add `YouAreDoingGreat`

### Issue: "Undefined symbol: _$s18YouAreDoingGreat..."

**Solution**: The app needs to be built before tests:
1. Build the app first: `Cmd+B`
2. Then run tests: `Cmd+U`

### Issue: SwiftData container errors

**Solution**: Tests use in-memory containers. If you see SwiftData errors:
1. Verify `TestContainer.swift` is in the test target
2. Check that `Moment` model is accessible to tests

### Issue: Tests timeout or hang

**Solution**: Some tests use small delays for async operations:
- Ensure you're running on a simulator (not device) for faster execution
- Check network mocks are properly configured

### Issue: Compilation errors in test files

**Solution**:
1. Ensure all test files are added to the `YouAreDoingGreatTests` target (not the main app)
2. Check that `@testable import YouAreDoingGreat` is at the top of each test file
3. Verify Swift Testing framework is available (requires Xcode 15+)

## CI/CD Verification

After setting up locally, verify CI/CD works:

1. Commit changes:
   ```bash
   git add .
   git commit -m "test: add comprehensive automated test suite (YADG-22)"
   ```

2. Push to a feature branch:
   ```bash
   git push origin feature/yadg-22-add-comprehensive-automated-test-suite
   ```

3. Create a pull request
4. Check GitHub Actions "Tests" workflow passes

## Code Coverage

To view code coverage after running tests:

1. In Xcode, go to "Report Navigator" (`Cmd+9`)
2. Select the latest test run
3. Click the "Coverage" tab
4. Expand to see coverage per file

**Target**: 70%+ coverage for business logic (Services, ViewModels, Repositories)

## Next Steps

### Add More Tests

Priority areas for additional test coverage:

1. **LogMomentViewModel**: Test moment creation flow
2. **PraiseViewModel**: Test praise display and animations
3. **MomentDetailViewModel**: Test detail view actions
4. **SyncService**: Test retry logic and exponential backoff
5. **UI Tests**: Critical flows (log moment, filter, delete, navigation)

### Test File Template

```swift
import Testing
import SwiftData
@testable import YouAreDoingGreat

@Suite("Feature Name Tests")
@MainActor
struct FeatureNameTests {
    var viewModel: FeatureViewModel!
    var mockAPI: MockAPIClient!
    var repository: MomentRepository!
    var context: ModelContext!

    init() async throws {
        context = try TestContainer.makeInMemoryContext()
        repository = SwiftDataMomentRepository(modelContext: context)
        mockAPI = MockAPIClient()
        viewModel = FeatureViewModel(
            service: Service(apiClient: mockAPI, repository: repository)
        )
    }

    @Test("Test description")
    func testName() async throws {
        // Arrange

        // Act

        // Assert
        #expect(condition)
    }
}
```

## Additional Resources

- [Swift Testing Documentation](https://developer.apple.com/documentation/testing)
- [Testing SwiftData Apps](https://developer.apple.com/videos/play/wwdc2023/10195/)
- [Xcode Test Documentation](https://developer.apple.com/documentation/xctest)
- Project `README.md` for architecture and patterns
- `CLAUDE.md` for development guidelines

## Questions?

If you encounter issues not covered here, please:
1. Check the error message carefully
2. Verify test target configuration
3. Try cleaning the build folder (`Cmd+Shift+K`)
4. Create an issue with detailed error logs
