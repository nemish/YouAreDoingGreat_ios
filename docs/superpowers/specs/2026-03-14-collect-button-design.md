# Collect Button — Hold-to-Collect Pill

## Context

The current `SparksDisplayView` uses a long-press on the orb itself to collect sparks, with a plain "hold to collect" text hint below. This is not discoverable — users don't expect to long-press a number. Adding a dedicated "Collect" button makes the action obvious while keeping the orb as an alternative touch target.

**Scope**: `SparksDisplayView.swift` only. No changes to parent views, view models, or services.

## Requirements & Definition of Done

### Layout

- Remove the standalone "hold to collect" hint text
- Add a capsule button below the orb, inside the existing `VStack(spacing: 12)`
- Both the orb and the button accept long-press gestures that drive the same collection state

### Button Visual States

#### Idle

- **Shape**: Capsule, ~200pt wide, ~48pt tall
- **Label**: "Collect" in `.comfortaa(16, weight: .bold)`, `appPrimary` color, centered
- **Background**: `appPrimary.opacity(0.12)` fill
- **Border**: 1pt `appPrimary.opacity(0.3)` capsule stroke
- **Subtitle**: "hold" in `.appCaption`, `.textTertiary`, `opacity(0.7)`, positioned below the label text (inside the button, small)
- **Breathing**: Subtle border opacity oscillation matching the orb's glow cycle (0.3→0.6 on 2s easeInOut)

#### Pressing (during 1s hold)

- **Fill animation**: A capsule overlay fills from leading to trailing edge, proportional to `collectProgress`. Fill color: `appPrimary`.
- **Label transition**: As the fill passes behind the text, the label color transitions from `appPrimary` to `.white` (use `blendMode` or track progress to swap color at ~50%).
- **Subtitle**: Fades to 0 opacity.
- **Scale**: Button scales 1.0→1.04 proportional to progress.
- **Haptic**: Same thresholds fire (25/50/75% light, 100% medium) — shared with orb since they drive the same state.
- **Orb reacts simultaneously**: Particles spiral in, glow intensifies, energy ring fills — all driven by the shared `collectProgress`.

#### Completed (progress = 1.0)

- Fill reaches 100%, brief white flash across button (same 0.15s timing as orb flash).
- Label changes to checkmark icon (`checkmark`) for 0.3s before `onCollect()` fires and parent transitions.
- Orb burst particles + number punch fire simultaneously.

#### Cancelled (release before 1s)

- Fill rewinds via the existing timer-driven easeOut (0.3s).
- Label returns to `appPrimary` color.
- Subtitle fades back to 0.7 opacity.
- Scale returns to 1.0.

### Dual Touch Targets

- **Remove** the existing `onLongPressGesture` from the outer `VStack`
- Apply `onLongPressGesture` individually to (a) the `TimelineView` ZStack (orb) and (b) the collect button
- Both gestures call the same `handlePressStart()` / `handlePressEnd()` methods
- Both drive the same `@State` properties — no duplication of progress/haptic logic
- If the user holds the orb, the button also visually fills (and vice versa)

### Accessibility

- Change outer VStack from `.accessibilityElement(children: .combine)` to `.accessibilityElement(children: .contain)` so both the orb and button are reachable as separate VoiceOver targets
- Orb keeps its existing `.accessibilityLabel("+N sparks earned")`
- Button has `.accessibilityLabel("Collect sparks")` and `.accessibilityHint("Long press to collect \(sparksAwarded) sparks")`
- `accessibilityReduceMotion`: Disable fill animation, breathing glow. Keep functional progress and label changes.

### API (unchanged)

```swift
struct SparksDisplayView: View {
    let sparksAwarded: Int
    let onCollect: () -> Void
}
```

### Definition of Done

- [ ] Capsule "Collect" button visible below the orb
- [ ] "hold" subtitle visible in idle, fades during press
- [ ] Long-press on button fills it left-to-right over 1s
- [ ] Long-press on orb also fills the button (shared state)
- [ ] Label transitions from amber to white as fill progresses
- [ ] Brief checkmark shown on completion before transition
- [ ] Cancel rewinds fill smoothly
- [ ] Haptics fire at 25/50/75/100% from either touch target
- [ ] `accessibilityReduceMotion` respected
- [ ] Accessibility labels on button
- [ ] No changes to parent views or API

## Technical

### Implementation approach

Modify `SparksDisplayView.swift` only.

**Button subview**: New `collectButton` computed property returning the capsule. Uses existing `collectProgress`, `isPressing`, `currentGlowOpacity` state — no new state needed for the button itself except a `@State var showCheckmark: Bool` for the brief completion indicator.

**Fill overlay**: A `Capsule().fill(appPrimary)` clipped to `width * collectProgress` using a `GeometryReader` or `.frame(width:)` inside an `HStack` with a `Spacer`. Clipped to capsule shape.

**Label color**: Conditional on `collectProgress > 0.5` — switches from `appPrimary` to `.white`. Animated via the existing `TimelineView` tick (no separate animation needed since progress is timer-driven).

**Dual gesture**: Remove the existing `onLongPressGesture` from the outer VStack. Apply it individually to the `TimelineView` block (orb) and to the collect button. Both call `handlePressStart()` / `handlePressEnd()`. Since they drive the same `@State`, everything stays in sync.

**Checkmark timing**: `showCheckmark` is set to `true` at collection completion. The existing 0.3s delay before `onCollect()` fires gives time for the checkmark to be visible. The parent removes this view after `onCollect()` returns — the checkmark only needs to persist for that 0.3s window.

**Remove**: The `hintText` computed property, `hintOffset` state variable, and their usage in `body` and `startEntrance()`.

### Files changed

- `YouAreDoingGreat/Features/Praise/Views/Components/SparksDisplayView.swift`

### Files unchanged

- `PraiseView.swift`, `PraiseViewModel.swift`, `ChapterProgressBar.swift`, `ChapterUnlockedOverlay.swift`
