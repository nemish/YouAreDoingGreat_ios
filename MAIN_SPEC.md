You Are Doing Great – iOS App Specification (v1)

Last updated: {{DATE}}
Author: Yara & ChatGPT

0. Purpose & Core Loop

App Purpose:
A lightweight emotional-wellness app where users log small daily wins, receive instant encouragement, and track their progress over time.

Core Loop:

User does something (tiny or big).

Opens app → taps a button → logs the moment.

Immediately receives offline praise (no delay).

AI-enhanced praise arrives a few seconds later (UI updates smoothly).

Over days/weeks, users view progress via Moments list + Journey timeline.

Design Principles

Minimal friction (1–2 taps for main action).

Warm, supportive tone.

Beautiful, calm visual atmosphere (cosmic gradient, floating stars).

Instant feedback.

Zero shame, zero pressure.

1. App Architecture (high-level)

Platform: iOS 17+
UI Framework: SwiftUI
Architecture Style: MVVM + lightweight reducers per module
Concurrency: async/await
Networking: URLSession + decodable models
Storage:

Local moments storage: SwiftData

User settings: AppStorage / UserDefaults

Offline praise pool: local JSON
AI Integration: Server-side via Node.js API → simple POST endpoint
Design System:

Primary color: pink/magenta glow

Background: dark cosmos gradient with slow-moving stars

Typography: SF Rounded / SF Pro

Haptics: light impact on main actions

Modules:

App
├── Home
├── LogMoment
├── Praise
├── MomentsList
├── Journey
├── Paywall
├── Settings
├── Shared (Components / Styles / Helpers)

2. Navigation Structure

Use TabView with 3 tabs:

Home

Moments

Journey

Plus modals:

Log Moment sheet

Time Picker bottom sheet

Paywall

Legal pages via SafariView

3. Screen Specifications

Below are exact screen definitions including copy, behavior, and interaction.

3.1 Onboarding (minimal v1)
Screen: Welcome

UI elements:

Title: You Are Doing Great

Subtitle: Log your small wins and get instant encouragement.

CTA Button: Get started

Footer: Privacy Policy • Terms of Use

Behavior:

On tap → go to Home

3.2 Home Screen

Purpose: Starting point, emotional entry.

UI:

Background: animated starfield

Center text (breathing): random supportive phrase

Primary button: I Did a Thing

Subtext: Tap to log something you did. Big or small, it counts.

Behavior:

Tap → present Log Moment screen

Top-right actions:

Settings icon

3.3 Log Moment Screen

Purpose: User describes what they did and when.

UI:

Title: Nice — that counts. What did you do?

Multiline TextEditor

Time row:

⏱ Happened just now
[ Change time ]

Time Bottom Sheet:

Title: When did it happen?

Numeric input [ 5 ]

Picker [ minutes | hours | days ]

Static text: ago

Button: Done

Secondary: Set to just now

Bottom CTA: Save this moment

On Save:

Save to SwiftData

Navigate to Praise Screen

3.4 Praise Screen

Purpose: Deliver instant emotional reinforcement.

UI Layout:

Header: Moment logged

Card with moment text + time

Offline praise (instant):
“Nice move, champ.”

AI praise (replace via fade)

Bottom actions:

Done

View today’s moments

Edge cases:

If AI fails: keep offline praise
Optional note: Couldn't fetch extra encouragement this time.

3.5 Moments Screen (Tab 2)

Purpose: Chronological list of user moments.

UI:

Title: Moments

Sectioned list:

Today
• Cleaned something quietly bothering me
5 min ago · “You made space for yourself.”

Empty state:

No moments yet… but you’re here, so that’s one.

Button: Log your first moment

3.6 Journey Screen (Tab 3)

Purpose: Show long-term progress and daily summaries.

UI:

Title: Your journey

Subtitle: Tiny steps, day by day.

Daily card example:

Oct 25, 2025 🙂 Calm day
3 moments logged

• Cleaned something quietly bothering me
• Took a short walk
• Called a friend

Summary:
“Steady, gentle progress. You took care of small things today.”

Empty state:
Once you have a few days of moments, you’ll see your journey here.

3.7 Paywall Screen

UI:

Title: You're doing great. Let's keep it going.

Subheader: Unlock more praise and deeper insights.

Benefits:

Unlimited AI encouragement

Daily summaries

Future features

Plans:

Yearly (recommended): 7-day free trial, $X.99/year

Monthly: $Y.99/month

CTA: Start 7-day free trial

Legal text: Small, Apple-compliant

3.8 Settings Screen

Sections:

Subscription

Manage Subscription

Restore Purchases

Privacy & Data

Delete my data

Privacy Policy

Terms of Use

Support

Support URL

Contact us

About

App version

Crisis disclaimer

4. State Management

AppState includes:

Current tab

Moments array

Offline praise pool

AI result

Paywall eligibility

ViewModels:
One per module:

HomeViewModel

LogMomentViewModel

PraiseViewModel

MomentsViewModel

JourneyViewModel

PaywallViewModel

SettingsViewModel

Use @MainActor and ObservableObject.

5. Offline & Error Handling
   Offline Praise

Always show instantly.

AI replaces when arrives.

Slow AI

Keep offline praise and animated subtitle.

Network Error

Subtle message:
Couldn't fetch extra encouragement this time.

6. Data Models (SwiftData)
   Moment
   @Model
   struct Moment {
   @Attribute(.unique) var id: UUID
   var text: String
   var createdAt: Date // timestamp of logging
   var loggedAt: Date // user-specified “when it happened”
   var aiPraise: String?
   var offlinePraise: String
   }

DailySummary (optional)
struct DailySummary {
var date: Date
var momentCount: Int
var summaryText: String?
}

7. Visual Style Guide
   Colors

Background: deep navy → soft blue

Accent: pink/magenta glow

Text: off-white

Effects

Starfield animation

Breathing text

Fade transitions (0.2–0.35s)

Haptics

Light impact for primary taps

Medium for “moment saved”

Light tick for tab switch

8. v1 Scope Checklist
   Core

Home screen

Log Moment + Time Picker

Praise screen

Moments list

Journey timeline

Settings

Paywall

SwiftData models

AI integration

Minimal onboarding

Extras

Offline praise JSON

Basic analytics

Smooth animations

9. Out of Scope (Future Versions)

Themes / tone selection

Notifications

Social constellation view

Weekly summaries

iCloud sync

Advanced insights

10. Required Legal Links

/privacy-policy

/terms

/support

Opened as SafariView.
