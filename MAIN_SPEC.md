# You Are Doing Great – iOS App Specification (v1)

**Last updated:** November 2024
**Authors:** Yara & ChatGPT

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
- **Warm, supportive tone** – Zero shame, zero pressure
- **Beautiful, calm visual atmosphere** – Cosmic gradient, floating stars
- **Instant feedback** – Always show something positive immediately
- **Zero pressure** – No streaks, no guilt, no judgment

---

## 1. App Architecture (High-Level)

### Technical Stack

| Component | Technology |
|-----------|------------|
| **Platform** | iOS 17+ |
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + lightweight reducers per module |
| **Concurrency** | async/await |
| **Networking** | URLSession + Codable models |
| **Local Storage** | SwiftData |
| **User Settings** | AppStorage / UserDefaults |
| **Offline Praise** | Local JSON pool |
| **AI Integration** | Server-side via Node.js API (simple POST endpoint) |

### Design System

**Colors:** (Defined in `Assets.xcassets`)
- **Primary**: Warm amber/gold accent (#E59500 light, #FFB84C dark)
- **Secondary**: Soft purple/lavender (#8A63D2 light, #A88BFA dark)
- **Background**: Cosmic gradient - Deep navy (#0F111C) in dark mode
- **Text**: Off-white (#F2F2F7) in dark mode, near-black (#1C1C1E) in light mode

**Typography:**
- SF Rounded / SF Pro

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

## 2. Navigation Structure

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

## 3. Screen Specifications

Below are exact screen definitions including copy, behavior, and interaction.

### 3.1 Onboarding (Minimal v1)

**Screen:** Welcome

**UI Elements:**
- **Title:** "You Are Doing Great"
- **Subtitle:** "Log your small wins and get instant encouragement."
- **CTA Button:** "Get started"
- **Footer:** "Privacy Policy • Terms of Use"

**Behavior:**
- On tap "Get started" → navigate to Home

---

### 3.2 Home Screen

**Purpose:** Starting point, emotional entry.

**UI:**
- **Background:** Animated starfield
- **Center text (breathing animation):** Random supportive phrase
- **Primary button:** "I Did a Thing"
- **Subtext:** "Tap to log something you did. Big or small, it counts."
- **Top-right action:** Settings icon

**Behavior:**
- Tap "I Did a Thing" → present Log Moment screen (modal)

---

### 3.3 Log Moment Screen

**Purpose:** User describes what they did and when.

**UI:**
- **Title:** "Nice — that counts. What did you do?"
- **Multiline TextEditor** – User input for moment text
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
2. Navigate to Praise Screen

---

### 3.4 Praise Screen

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

### 3.5 Moments Screen (Tab 2)

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

### 3.6 Journey Screen (Tab 3)

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

### 3.7 Paywall Screen

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

### 3.8 Settings Screen

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

## 4. State Management

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

## 5. Offline & Error Handling

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

## 6. Data Models (SwiftData)

### Moment

```swift
@Model
class Moment {
    @Attribute(.unique) var id: UUID
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
}
```

### DailySummary (Optional)

```swift
struct DailySummary {
    var date: Date
    var momentCount: Int
    var summaryText: String?
}
```

---

## 7. Visual Style Guide

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

- **Starfield animation** – Slow-moving stars in background
- **Breathing text** – Scale + opacity animation
- **Fade transitions** – 0.2–0.35s duration
- **CosmicGradient** – Background gradient (BackgroundTertiary → Background)

### Haptics

- **Light impact** – Primary taps
- **Medium impact** – "Moment saved" confirmation
- **Light tick** – Tab switch

---

## 8. v1 Scope Checklist

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

## 9. Out of Scope (Future Versions)

- Themes / tone selection
- Push notifications
- Social constellation view
- Weekly summaries
- iCloud sync
- Advanced insights
- Widgets
- Apple Watch companion app

---

## 10. Required Legal Links

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
