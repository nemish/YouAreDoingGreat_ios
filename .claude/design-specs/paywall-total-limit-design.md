# Paywall & Limit System Design Specification

## Overview

This document specifies the design for implementing `TOTAL_LIMIT_REACHED` handling (similar to existing `DAILY_LIMIT_REACHED`) and updating premium vs free usage texts throughout the iOS app.

---

## Current State Analysis

### Existing Limit Handling

| Component | Current Behavior |
|-----------|-----------------|
| `APIErrorCode` | Has `dailyLimitReached` case, missing `totalLimitReached` |
| `MomentError` | Has `dailyLimitReached(message:)` case, missing total limit |
| `PaywallService` | Manages `dailyLimitReached` state only |
| `PaywallTrigger` | Has `.dailyLimitReached`, `.timelineRestricted`, `.manualTrigger` |
| API Schema | Supports both `DAILY_LIMIT_REACHED` and `TOTAL_LIMIT_REACHED` error codes |

### Current Text Issues (Incorrect/Outdated)

| Location | Current Text | Issue |
|----------|-------------|-------|
| `PaywallView.swift:101` | "Unlock up to 30 praises per day" | Should be "up to 10 moments per day" |
| `ProfileView.swift:278` | "Enjoy 50 moments per day and advanced analytics" | Should be "Enjoy up to 10 moments per day" |
| `ProfileView.swift:279` | "Limited to 3 moments per day" | Correct, but should also mention "10 total" |
| `PremiumThankYouCard.swift:25` | "up to 30 moments a day" | Should be "up to 10 moments a day" |

---

## New Limits Summary

| User Type | Daily Limit | Total Limit |
|-----------|-------------|-------------|
| **Free** | 3 moments/day | 10 moments total (lifetime) |
| **Premium** | 10 moments/day | Unlimited |

---

## Design Specification

### 1. API Error Handling

#### 1.1 Update `APIErrorCode` enum

**File:** `YouAreDoingGreat/Core/APIError.swift`

```swift
enum APIErrorCode: String, Decodable {
    // ... existing cases ...
    case dailyLimitReached = "DAILY_LIMIT_REACHED"
    case totalLimitReached = "TOTAL_LIMIT_REACHED"  // NEW
    // ...
}
```

#### 1.2 Update `MomentError` enum

**File:** `YouAreDoingGreat/Core/APIError.swift`

```swift
enum MomentError: LocalizedError {
    case dailyLimitReached(message: String)
    case totalLimitReached(message: String)  // NEW
    // ... existing cases ...

    var errorDescription: String? {
        switch self {
        case .dailyLimitReached(let message):
            return message
        case .totalLimitReached(let message):  // NEW
            return message
        // ...
        }
    }

    var isDailyLimitError: Bool {
        if case .dailyLimitReached = self { return true }
        return false
    }

    var isTotalLimitError: Bool {  // NEW
        if case .totalLimitReached = self { return true }
        return false
    }

    var isLimitError: Bool {  // NEW - convenience
        isDailyLimitError || isTotalLimitError
    }
}
```

---

### 2. PaywallService Updates

#### 2.1 Add Total Limit State

**File:** `YouAreDoingGreat/Services/PaywallService.swift`

```swift
enum PaywallTrigger {
    case dailyLimitReached
    case totalLimitReached      // NEW
    case timelineRestricted
    case manualTrigger
}

@MainActor
@Observable
final class PaywallService {
    // Existing state
    var shouldShowPaywall: Bool = false
    var dailyLimitReachedDate: Date?
    var paywallTrigger: PaywallTrigger = .manualTrigger
    var isTimelineRestricted: Bool = false

    // NEW: Total limit state
    var isTotalLimitReached: Bool = false

    // UserDefaults keys
    private let dailyLimitDateKey = "com.youaredoinggreat.dailyLimitDate"
    private let totalLimitReachedKey = "com.youaredoinggreat.totalLimitReached"  // NEW

    // NEW: Mark total limit reached
    func markTotalLimitReached() {
        isTotalLimitReached = true
        paywallTrigger = .totalLimitReached
        saveState()
        logger.info("Total limit reached, paywall activated permanently until upgrade")
    }

    // NEW: Check if user should be blocked for any limit
    func shouldBlockMomentCreation() -> Bool {
        checkIfNewDay()

        // Premium users bypass all limits
        if SubscriptionService.shared.hasActiveSubscription {
            return false
        }

        // Check total limit first (more permanent)
        if isTotalLimitReached {
            return true
        }

        return isDailyLimitReached
    }

    // Update reset for premium upgrade
    func resetAllLimits() {
        dailyLimitReachedDate = nil
        isTotalLimitReached = false
        shouldShowPaywall = false
        saveState()
        logger.info("All limits reset (premium upgrade)")
    }

    // Update state persistence
    private func saveState() {
        // ... existing daily limit save ...
        UserDefaults.standard.set(isTotalLimitReached, forKey: totalLimitReachedKey)
    }

    private func loadState() {
        // ... existing daily limit load ...
        isTotalLimitReached = UserDefaults.standard.bool(forKey: totalLimitReachedKey)
    }
}
```

---

### 3. PaywallView Updates

#### 3.1 Support Both Limit Types in UI

**File:** `YouAreDoingGreat/Features/Paywall/Views/PaywallView.swift`

```swift
struct PaywallView: View {
    // Computed properties
    private var isDailyLimitReached: Bool {
        PaywallService.shared.paywallTrigger == .dailyLimitReached
    }

    private var isTotalLimitReached: Bool {  // NEW
        PaywallService.shared.paywallTrigger == .totalLimitReached
    }

    private var isAnyLimitReached: Bool {  // NEW
        isDailyLimitReached || isTotalLimitReached
    }

    // Update body to show appropriate banner
    var body: some View {
        // ...

        // Limit banner (if applicable)
        if isAnyLimitReached {
            limitBanner  // Renamed from dailyLimitBanner
                .padding(.horizontal, 32)
                .padding(.top, 8)
        }

        // ...
    }

    // NEW: Unified limit banner with conditional text
    private var limitBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color(red: 0.86, green: 0.93, blue: 1.0))

            Text(limitBannerText)
                .font(.appBody)
                .fontWeight(.semibold)
                .foregroundStyle(Color(red: 0.86, green: 0.93, blue: 1.0))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.37, green: 0.64, blue: 0.95))
        )
        .scaleEffect(showContent ? 1 : 0.8)
        .opacity(showContent ? 1 : 0)
    }

    private var limitBannerText: String {
        if isTotalLimitReached {
            return "You've logged 10 moments. Go premium to keep celebrating your wins."
        } else {
            return "Daily limit reached. Go premium to continue without interruptions."
        }
    }
}
```

#### 3.2 Update Header Text

```swift
// Plans section header - update line 101
Text("Unlock up to 10 moments per day")
    .font(.appHeadline)
    .foregroundStyle(Color(red: 0.75, green: 0.85, blue: 1.0))
    .multilineTextAlignment(.center)
    .opacity(showPlans ? 1 : 0)
```

---

### 4. Moment Creation Error Handling

Update the moment creation flow to handle both error types.

**File:** Wherever moment creation errors are handled (e.g., `HomeViewModel.swift` or `MomentService.swift`)

```swift
// When handling API error response:
switch errorCode {
case .dailyLimitReached:
    PaywallService.shared.markDailyLimitReached()
    throw MomentError.dailyLimitReached(message: errorMessage)

case .totalLimitReached:  // NEW
    PaywallService.shared.markTotalLimitReached()
    throw MomentError.totalLimitReached(message: errorMessage)

// ...
}
```

---

### 5. Text Updates

#### 5.1 ProfileView.swift (Lines 274-279)

**From:**
```swift
Text(isPremium ? "Enjoy 50 moments per day and advanced analytics" : "Limited to 3 moments per day")
```

**To:**
```swift
Text(isPremium
    ? "Up to 10 moments per day, unlimited history"
    : "3 moments per day, 10 total")
```

#### 5.2 PremiumThankYouCard.swift (Line 25)

**From:**
```swift
private let benefits = [
    "up to 30 moments a day",
    "full journey history",
    "priority support (yep, I'm listening)"
]
```

**To:**
```swift
private let benefits = [
    "up to 10 moments a day",
    "unlimited total moments",
    "full journey history"
]
```

#### 5.3 PaywallView.swift (Line 101)

**From:**
```swift
Text("Unlock up to 30 praises per day")
```

**To:**
```swift
Text("Unlock up to 10 moments per day")
```

---

### 6. Localizable.strings Updates

**File:** `YouAreDoingGreat/Resources/Localizable.strings`

Add new strings:

```swift
/* Total Limit - Banner */
"total_limit_banner_text" = "You've logged 10 moments. Go premium to keep celebrating your wins.";

/* Daily Limit - Banner (existing, verify) */
"daily_limit_banner_text" = "Daily limit reached. Go premium to continue without interruptions.";

/* Subscription descriptions */
"subscription_premium_description" = "Up to 10 moments per day, unlimited history";
"subscription_free_description" = "3 moments per day, 10 total";

/* Premium benefits */
"premium_benefit_moments" = "up to 10 moments a day";
"premium_benefit_unlimited" = "unlimited total moments";
"premium_benefit_history" = "full journey history";
```

---

## Implementation Checklist

### Phase 1: Core Infrastructure
- [ ] Add `totalLimitReached` to `APIErrorCode` enum
- [ ] Add `totalLimitReached(message:)` to `MomentError` enum
- [ ] Add helper properties `isTotalLimitError`, `isLimitError` to `MomentError`
- [ ] Add `.totalLimitReached` to `PaywallTrigger` enum
- [ ] Add `isTotalLimitReached` state to `PaywallService`
- [ ] Add `markTotalLimitReached()` method to `PaywallService`
- [ ] Update `shouldBlockMomentCreation()` to check total limit
- [ ] Add `resetAllLimits()` method (called on premium upgrade)
- [ ] Update state persistence for total limit

### Phase 2: UI Updates
- [ ] Update `PaywallView` to handle both limit types
- [ ] Create unified `limitBanner` with conditional text
- [ ] Update paywall header: "30 praises" → "10 moments"

### Phase 3: Text Corrections
- [ ] `ProfileView.swift`: Update subscription descriptions
- [ ] `PremiumThankYouCard.swift`: Update benefits list
- [ ] `PaywallView.swift`: Update header text
- [ ] Add new strings to `Localizable.strings`

### Phase 4: Error Handling
- [ ] Update moment creation error handling to detect `TOTAL_LIMIT_REACHED`
- [ ] Trigger paywall with correct trigger type based on error

### Phase 5: Testing
- [ ] Test daily limit flow still works
- [ ] Test total limit detection from API
- [ ] Test paywall shows correct messaging for each limit type
- [ ] Test premium upgrade resets all limits
- [ ] Verify all texts display correctly

---

## Notes

1. **Total limit is permanent for free users** - Unlike daily limit which resets, total limit persists until premium upgrade
2. **API already supports this** - The backend returns `TOTAL_LIMIT_REACHED` with meta `{limit: 10, isPremium: false}`
3. **Warm tone** - All messaging maintains the app's supportive, non-judgmental voice
4. **Offline considerations** - If offline, we should still allow moment creation but sync will fail with limit error when online
