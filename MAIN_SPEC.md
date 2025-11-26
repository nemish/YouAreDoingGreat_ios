# You Are Doing Great – iOS App Specification (v1)

---

## 0. Purpose & Core Loop

### App Purpose

A lightweight emotional-wellness app where users log small daily wins, receive instant encouragement, and track their progress over time.

### Core Loop

1. User does something (tiny or big)
2. Opens app → taps a button → logs the moment
3. Immediately receives offline praise (no delay)
4. AI-enhanced praise arrives a few seconds later (UI updates smoothly)
5. Over days/weeks, users view progress via Moments list + Journey timeline

### Design Principles

- **Minimal friction** – 1–2 taps for main action
- **Optional richness** – Main log works with zero extra input, but users can add feelings, notes, or photos when they want
- **Warm, supportive tone** – Zero shame, zero pressure
- **Beautiful, calm visual atmosphere** – Cosmic gradient, floating stars
- **Instant feedback** – Always show something positive immediately
- **Zero pressure** – No streaks, no guilt, no judgment

---

## 1. App Architecture (High-Level)

### Technical Stack

| Component          | Technology                                         |
| ------------------ | -------------------------------------------------- |
| **Platform**       | iOS 17+                                            |
| **UI Framework**   | SwiftUI                                            |
| **Architecture**   | MVVM + lightweight reducers per module             |
| **Concurrency**    | async/await                                        |
| **Networking**     | URLSession + Codable models                        |
| **Local Storage**  | SwiftData                                          |
| **User Settings**  | AppStorage / UserDefaults                          |
| **Offline Praise** | Local JSON pool                                    |
| **AI Integration** | Server-side via Node.js API (simple POST endpoint) |

### Design System

**Colors:** (Defined in `Assets.xcassets`)

- **Primary**: Warm amber/gold accent (#E59500 light, #FFB84C dark)
- **Secondary**: Soft purple/lavender (#8A63D2 light, #A88BFA dark)
- **Background**: Cosmic gradient - Deep navy (#0F111C) in dark mode
- **Text**: Off-white (#F2F2F7) in dark mode, near-black (#1C1C1E) in light mode

**Typography:**

- **GloriaHallelujah** - Handwritten font for titles and headings
- **Comfortaa** - Rounded font for body text and UI elements

Custom fonts defined in `Font+Extensions.swift` with semantic styles:
- Titles: `.appLargeTitle`, `.appTitle`, `.appTitle2`, `.appTitle3`
- Body: `.appHeadline`, `.appBody`, `.appCallout`, `.appSubheadline`, `.appFootnote`, `.appCaption`

**Haptics:**

- Light impact for primary taps
- Medium impact for "moment saved"
- Light tick for tab switch

### Module Structure

```
App
├── Home
├── LogMoment
├── Praise
├── MomentsList
├── Journey
├── Paywall
├── Settings
└── Shared (Components / Styles / Helpers)
```

---

## 2. Anonymous User Identity System

### Overview

The app uses **anonymous user IDs** to provide a seamless, privacy-first experience without requiring sign-up or authentication. Every user gets a persistent UUID that serves as their identity across the app, API, and subscription system.

### Implementation Details

**1. UUID Generation & Persistence**

- Generate a random UUID on **first app launch**
- Persist to **Keychain** (preferred) or UserDefaults for durability across app reinstalls
- UUID format: Standard UUID v4 (e.g., `550e8400-e29b-41d4-a716-446655440000`)

**2. UserID Provider Service**

Create a lightweight `UserIDProvider` service accessible throughout the app:

```swift
@Observable
final class UserIDProvider {
    static let shared = UserIDProvider()
    private(set) var userID: String

    private init() {
        // Load from Keychain, or generate and save if first launch
        self.userID = KeychainManager.getUserID() ?? {
            let newID = UUID().uuidString
            KeychainManager.saveUserID(newID)
            return newID
        }()
    }
}
```

**3. API Integration**

- **All API requests** must include the `x-user-id` header
- Header value: The persistent UUID from `UserIDProvider.shared.userID`
- Backend treats this as the primary identity, lazily creating user records as needed

Example URLRequest setup:
```swift
request.setValue(UserIDProvider.shared.userID, forHTTPHeaderField: "x-user-id")
```

**4. Backend Behavior**

- Server receives `x-user-id` header
- If user record doesn't exist → create new user with this UUID
- If user record exists → fetch/update data for this UUID
- All moments, stats, and preferences are stored under this anonymous identity

**5. RevenueCat Integration**

- Use the **same UUID** as RevenueCat's `appUserID`
- This links subscription purchases to the anonymous identity
- Call `Purchases.configure(withAPIKey:appUserID:)` with the UUID

```swift
Purchases.configure(
    withAPIKey: "your_key",
    appUserID: UserIDProvider.shared.userID
)
```

**6. Future Authentication Migration**

When introducing real authentication (email/OAuth):

1. User signs in with credentials
2. Backend merges anonymous user data into authenticated account
3. Update stored UUID to match authenticated user ID
4. Update RevenueCat: `Purchases.shared.logIn(newUserID)`
5. All existing moments and purchases carry over seamlessly

### Security & Privacy Considerations

- **No personal data** stored in the UUID itself
- UUID stored in **Keychain** for secure, persistent storage
- Users remain completely anonymous until they choose to authenticate
- GDPR/CCPA compliant - no tracking without explicit consent
- UUID is **not** shared with third parties

### Edge Cases

**App Reinstall:**
- If Keychain data persists: User keeps same identity
- If Keychain cleared: New UUID generated, fresh start (intentional privacy feature)

**Device Transfer:**
- Without authentication: New device = new identity
- With future authentication: Sign in to restore data

**Multiple Devices:**
- Each device has separate anonymous identity initially
- Future authentication enables cross-device sync

### Implementation Checklist

- [ ] Create `KeychainManager` utility for secure UUID storage
- [ ] Implement `UserIDProvider` singleton service
- [ ] Add `x-user-id` header to all API requests
- [ ] Configure RevenueCat with the same UUID
- [ ] Add unit tests for UUID generation and persistence
- [ ] Document migration strategy for future authentication

---

## 3. Navigation Structure

### TabView (3 tabs)

1. **Home** – Main entry point
2. **Moments** – Chronological list
3. **Journey** – Daily summaries timeline

### Modals

- **Log Moment sheet** – Full-screen modal for logging
- **Time Picker bottom sheet** – Adjust when moment happened
- **Paywall** – Subscription screen
- **Legal pages** – Privacy Policy, Terms (via SafariView)

---

## 4. Screen Specifications

Below are exact screen definitions including copy, behavior, and interaction.

### 4.1 Onboarding (Minimal v1)

**Screen:** Welcome

**UI Elements:**

- **Tiny intro text (fades in above title):** "Hey. Glad you're here."
- **Hero title:** "You're doing better than you think"
- **Sub-headline:** "This app helps you notice the small wins you usually ignore… and feel a bit better"
- **CTA Button:** "Alright, let's do this"
- **Footer:** "Privacy Policy • Terms"
- **Visual treatment:** Starfield / gradient background mirroring Home, gentle motion on stars, copy fades sequentially (intro → title → sub-headline)

**Behavior:**

- On tap "Get started" → navigate to Home

**First-launch sequence requirements:**

1. Welcome screen → user taps “Alright, let’s do this.”
2. Home screen loads and shows the single-use hint beneath the main CTA.
3. First tap on “I Did a Thing” auto-populates the log text with `"I installed this app. A tiny step, but it counts."`
4. User saves the moment, lands on Praise, and `hasCompletedFirstLog` flips to true so the hint never appears again (unless reinstall / data reset).

**Testing checklist:**

- Hint renders only on the first-ever Home display and disappears permanently after the first successful moment log.
- Pre-filled copy appears exactly once and is fully editable; subsequent logs open empty.
- Relaunches and cold starts respect the stored `hasCompletedFirstLog` flag so returning users never see the hint again.

---

### 4.2 Home Screen

**Purpose:** Starting point, emotional entry.

**UI:**

- **Background:** Animated starfield
- **Center text (breathing animation):** Random phrase from pool of 20 humorous/self-deprecating messages. Tap to cycle to next phrase with animation and haptic feedback.
- **Primary button:** "I Did a Thing"
- **Top-right action:** Settings icon

**Behavior:**

- First-launch hint: when `hasCompletedFirstLog == false`, render a single-use helper line under the primary button: “Hey… installing the app counts too. Wanna log that tiny win?” (appears only until the first successful log is saved)
- Tap "I Did a Thing" → present Log Moment screen (modal); if `hasCompletedFirstLog == false`, pre-fill text field with `"I installed this app. A tiny step, but it counts."` (user can edit/clear freely, only occurs on that first tap)
- Persist first-log completion via `@AppStorage("hasCompletedFirstLog") var hasCompletedFirstLog: Bool = false`; set to `true` immediately after the first moment save succeeds so the hint never reappears unless the app is reinstalled

---

### 4.3 Log Moment Screen

**Purpose:** User describes what they did and when.

**UI:**

- **Title:** "Nice — that counts. What did you do?"
- **Multiline TextEditor** – User input for moment text (optional; if left blank we store a private placeholder locally)
- **First moment pre-fill:** when invoked from Home while `hasCompletedFirstLog == false`, show the default copy `"I installed this app. A tiny step, but it counts."` inside the TextEditor; this only happens once
- **Optional enrichments:** lightweight fields to capture mood (picker), freeform note, and 0–n photo attachments; all hidden/collapsed by default so a user can just tap save with no extra steps
- **Time row:**
  - Icon: ⏱
  - Label: "Happened just now"
  - Button: "Change time"
- **Bottom CTA:** "Save this moment"

**Time Picker Bottom Sheet:**

- **Title:** "When did it happen?"
- **Numeric input:** `[ 5 ]`
- **Picker:** `[ minutes | hours | days ]`
- **Static text:** "ago"
- **Buttons:**
  - Primary: "Done"
  - Secondary: "Set to just now"

**On Save:**

1. Save moment to SwiftData (with client UUID)
   - Persist optional metadata (mood tag, note text, photo references) when present; store null/empty otherwise with no prompts
   - If `hasCompletedFirstLog == false`, set it to `true` immediately after a successful save (this also permanently hides the Home hint)
2. Navigate to Praise Screen

---

### 4.4 Praise Screen

**Purpose:** Deliver instant emotional reinforcement.

**UI Layout:**

- **Header:** "Moment logged"
- **Card:** Moment text + time
- **Offline praise (instant):** e.g., "Nice move, champ."
- **AI praise:** Replaces offline via fade animation when available
- **Bottom actions:**
  - "Done"
  - "View today's moments"

**Edge Cases:**

- If AI fails: Keep offline praise
- Optional subtle note: "Couldn't fetch extra encouragement this time."

---

### 4.5 Moments Screen (Tab 2)

**Purpose:** Chronological list of user moments.

**UI:**

- **Title:** "Moments"
- **Sectioned list:**
  - Section header: "Today"
  - Row example:
    - "Cleaned something quietly bothering me"
    - "5 min ago · 'You made space for yourself.'"

**Empty State:**

- Message: "No moments yet… but you're here, so that's one."
- Button: "Log your first moment"

---

### 4.6 Journey Screen (Tab 3)

**Purpose:** Show long-term progress and daily summaries.

**UI:**

- **Title:** "Your journey"
- **Subtitle:** "Tiny steps, day by day."

**Daily Card Example:**

```
Oct 25, 2025 🙂 Calm day
3 moments logged

• Cleaned something quietly bothering me
• Took a short walk
• Called a friend

Summary:
"Steady, gentle progress. You took care of small things today."
```

**Empty State:**

- Message: "Once you have a few days of moments, you'll see your journey here."

---

### 4.7 Paywall Screen

**UI:**

- **Title:** "You're doing great. Let's keep it going."
- **Subheader:** "Unlock more praise and deeper insights."

**Benefits:**

- Unlimited AI encouragement
- Daily summaries
- Future features

**Plans:**

- **Yearly (recommended):** 7-day free trial, $X.99/year
- **Monthly:** $Y.99/month

**CTA:** "Start 7-day free trial"

**Legal text:** Small, Apple-compliant disclaimer

---

### 4.8 Settings Screen

**Sections:**

**Subscription**

- Manage Subscription
- Restore Purchases

**Privacy & Data**

- Delete my data
- Privacy Policy
- Terms of Use

**Support**

- Support URL
- Contact us

**About**

- App version
- Crisis disclaimer

---

## 5. State Management

### AppState Includes

- Current tab
- Moments array
- Offline praise pool
- AI result
- Paywall eligibility

### ViewModels (One per Module)

- `HomeViewModel`
- `LogMomentViewModel`
- `PraiseViewModel`
- `MomentsViewModel`
- `JourneyViewModel`
- `PaywallViewModel`
- `SettingsViewModel`

**Pattern:** Use `@MainActor` and `@Observable` (iOS 17+)

---

## 6. Offline & Error Handling

### Offline Praise

- **Always show instantly** – Never wait for network
- **AI replaces when it arrives** – Smooth fade transition

### Slow AI

- Keep offline praise visible
- Show animated subtitle while waiting

### Network Error

- Keep offline praise
- Show subtle message: "Couldn't fetch extra encouragement this time."

---

## 7. Data Models (SwiftData)

### Moment

```swift
@Model
class Moment {
    @Attribute(.unique) var id: UUID       // Client-generated UUID
    var serverId: String?                   // Server-assigned ID (after sync)
    var text: String
    var submittedAt: Date      // Timestamp of logging
    var happenedAt: Date       // User-specified "when it happened"
    var tz: String             // User timezone
    var timeAgo: Int?          // Seconds between happenedAt and submittedAt
    var aiPraise: String?      // AI-generated praise (optional)
    var offlinePraise: String  // Instant offline praise
    var action: String?        // Normalized action (e.g., "exercise")
    var tags: [String]         // Extracted tags
    var isFavorite: Bool       // User-marked favorite
    var isSynced: Bool         // Local sync status
    var syncError: String?     // Last sync error message
}
```

### Offline-First Sync Pattern

1. **Create locally**: Generate client UUID, show offline praise instantly
2. **POST to server**: Send `clientId` (the client UUID) with moment data
3. **Server responds**: Returns server-generated `id` plus echoed `clientId`
4. **Update locally**: Store `serverId`, mark as synced, update with AI praise
5. **Retry on failure**: Exponential backoff for failed syncs

### DailySummary (Optional)

```swift
struct DailySummary {
    var date: Date
    var momentCount: Int
    var summaryText: String?
}
```

---

## 8. Visual Style Guide

### Colors

**All colors defined in `Assets.xcassets` with light/dark mode support.**

**Primary Palette:**

- **Primary:** Warm amber/gold accent (#E59500 → #FFB84C)
- **Secondary:** Soft purple/lavender (#8A63D2 → #A88BFA)

**Backgrounds:**

- **Background:** Almost white → Deep navy (#FAFAFC → #0F111C)
- **BackgroundSecondary:** White → Lighter navy (#FFFFFF → #191C2A)
- **BackgroundTertiary:** Light gray → Medium navy (#F2F2F7 → #232634)

**Text:**

- **TextPrimary:** Near-black → Off-white (#1C1C1E → #F2F2F7)
- **TextSecondary:** Medium gray → Light gray (#636366 → #98989D)
- **TextTertiary:** Light gray → Dark gray (#AEAEB2 → #636366)

**Semantic:**

- **Success:** Green (#34C759 → #30D158)
- **Error:** Red (#FF3B30 → #FF453A)
- **Warning:** Orange (#FF9500 → #FF9F0A)
- **Star:** Purple 30% → White 80% (for starfield)

### Effects

- **Starfield animation** – 500 static stars with group animations:
  - Stars vary in size (0.8-3.0px) and opacity (0.3-0.8) for depth
  - Entire layer animates: drift (20s), rotation ±30° (60s), scale 1.0-1.1 (25s)
  - Two fog/nebula radial gradients (top-trailing, bottom-leading) with slow drift
- **Breathing text** – Scale + opacity animation
- **Fade transitions** – 0.2–0.35s duration
- **CosmicGradient** – Background gradient (BackgroundTertiary → Background)

### Haptics

- **Light impact** – Primary taps
- **Medium impact** – "Moment saved" confirmation
- **Light tick** – Tab switch

---

## 9. v1 Scope Checklist

### Core Features

- [x] Home screen
- [x] Log Moment + Time Picker
- [x] Praise screen (offline + AI)
- [x] Moments list (chronological)
- [x] Journey timeline (daily summaries)
- [x] Settings
- [x] Paywall
- [x] SwiftData models
- [x] AI integration
- [x] Minimal onboarding

### Extras

- [x] Offline praise JSON pool
- [x] Basic analytics
- [x] Smooth animations

---

## 10. Out of Scope (Future Versions)

- Themes / tone selection
- Push notifications
- Social constellation view
- Weekly summaries
- iCloud sync
- Advanced insights
- Widgets
- Apple Watch companion app

---

## 11. Required Legal Links

All legal pages opened via SafariView:

- `/privacy-policy` – Privacy Policy
- `/terms` – Terms of Use
- `/support` – Support page

---

## Notes

- **Tone:** Always warm, supportive, and encouraging. Never judgmental or pressure-inducing.
- **Performance:** Optimize for instant feedback. User should never wait to see praise.
- **Privacy:** This is not a crisis intervention app. Include appropriate disclaimers.
- **Offline-first:** Moments created locally first, synced to server in background for AI enrichment.
- **Dark Mode Only (v1):** App currently supports dark mode only. Light mode infrastructure exists in asset catalog but is not active. App enforces dark mode via `.preferredColorScheme(.dark)`. Light mode can be added later by removing this modifier and adjusting color values.
