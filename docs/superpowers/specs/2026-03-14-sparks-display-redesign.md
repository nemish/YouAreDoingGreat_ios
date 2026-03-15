# Sparks Display Redesign — Energy Absorption

## Context

The current `SparksDisplayView` feels like a placeholder: a flat radial gradient behind text with a thin progress ring on long-press. It needs to feel like a rewarding power-up moment — premium, layered, and satisfying.

**Scope**: Only `SparksDisplayView`. The `ChapterProgressBar` and `ChapterUnlockedOverlay` remain unchanged.

## Requirements & Definition of Done

### Visual States

#### Entrance

- Keep existing spring entrance: scale 0.8→1.0, opacity 0→1, spring(response: 0.4, dampingFraction: 0.7) with 0.2s delay. Orbiting particles fade in with the rest.

#### Idle (before pressing)

- **Layered orb**: Multiple concentric rings of amber light at different opacities (3 rings minimum), creating a sense of depth — like a small star rather than a flat gradient blob. Breathing glow oscillates between 0.3 and 0.6 opacity on a 2.0s easeInOut cycle.
- **Orbiting particles**: 6-8 small bright dots orbiting the orb at varying radii (30-45pt from center, all inside the energy ring) and angular speeds. Mix of amber and white-amber tones. Creates ambient energy feel.
- **Number display**: "+N" in `comfortaa(32, weight: .bold)` (bumped from 28). "sparks" label below in `.appCaption` (unchanged). Both pulse gently with the orb's breathing glow.
- **Hint text**: "hold to collect" styled with `.appFootnote`, opacity 0.7, with subtle upward float animation (2pt vertical oscillation over 2s).
- **Ambient halo**: 2-3 layered radial gradients at different radii creating depth instead of single flat gradient. Outer radius ~80pt.

#### Pressing (during 1s long-press)

- **Particles spiral inward**: Orbiting dots decrease their orbital radius proportional to `collectProgress` (0→1). At ~80% they're tight and fast-spinning. At 100% they converge to center.
- **Energy ring**: 5pt stroke width (up from 2.5pt). Gradient fill from `appPrimary` to `white.opacity(0.8)` at the leading edge. Soft glow shadow on the ring's leading edge. Diameter 90pt (up from 80pt).
- **Orb intensifies**: Inner glow opacity increases from 0.3→0.7 as progress increases. Concentric rings tighten (radii shrink ~20%).
- **Haptic ramp**: `UIImpactFeedbackGenerator(.light)` fires at progress milestones: 0.25, 0.5, 0.75, then `.medium` at 1.0. Creates a tactile "charging up" feel.
- **Scale**: Orb scales 1.0→1.08 proportional to progress via spring animation.
- **"hold to collect"** fades to 0 opacity (existing behavior).

#### Collected (on completion at progress = 1.0)

- **Flash**: Brief white overlay circle, opacity 0→0.6→0 over 0.15s.
- **Particle burst**: 20-30 tiny circles (2-4pt) explode outward from center at random angles and speeds (150-300pt travel). Mix of `appPrimary`, white, and `appPrimary.opacity(0.6)`. Fade out over 0.6s.
- **Number punch**: "+N" springs from 1.0→1.2→1.0 scale (response: 0.3, damping: 0.5) with brief white tint.
- **Haptic**: `.medium` impact feedback — satisfying "collected" thud.
- **Sequencing**: The burst animation is fire-and-forget. `onCollect()` fires after a 0.3s delay (enough for the flash + number punch to land). The parent's 0.5s crossfade transition to `ChapterProgressBar` overlaps with the tail of the burst — this is fine since the burst particles are fading out anyway.

#### Cancelled (release before 1s)

- Particles drift back to original orbital radii over 0.3s (easeOut).
- Energy ring rewinds to 0 (existing 0.2s easeOut).
- Orb glow/scale return to idle values.
- No haptic on cancel.

### Accessibility

- `accessibilityReduceMotion`: Disable orbiting particles, haptic ramp, particle burst, float animation. Keep simple opacity/scale entrance and the functional ring progress.
- Accessibility label: "+N sparks earned"
- Accessibility hint: "Long press to collect sparks"
- `accessibilityElement(children: .combine)` on the container.

### Performance

- Use `TimelineView(.animation)` for orbiting particles (smooth 60fps).
- Burst particles via `Canvas` view for efficient rendering of 20-30 simultaneous elements.
- All animation state is local `@State` — no service or model changes.

### API (unchanged)

```swift
struct SparksDisplayView: View {
    let sparksAwarded: Int
    let onCollect: () -> Void
}
```

### Definition of Done

- [ ] Idle state shows layered orb with orbiting particles
- [ ] Long-press shows energy ring filling, particles spiraling in, orb intensifying
- [ ] Haptic ramp fires at 25/50/75/100% milestones
- [ ] Collection triggers flash + particle burst + number punch
- [ ] Cancel gracefully rewinds all visual state
- [ ] `accessibilityReduceMotion` disables non-essential animations
- [ ] Accessibility labels and hints present
- [ ] No performance regression (Canvas for burst particles)
- [ ] Previews work and show all states
- [ ] Existing integration unchanged — same props, same callback

## Technical

### Implementation approach

Single file replacement of `SparksDisplayView.swift`. No changes to parent views, view models, or services.

**Particle orbit system**: `TimelineView(.animation)` drives a `Date`-based angle calculation for each particle. Each particle has a fixed `angularSpeed`, `baseRadius`, and `phase` offset. During pressing, `baseRadius` is interpolated toward 0 based on `collectProgress`.

**Burst system**: On collection, spawn 20-30 `BurstParticle` structs with random angles and speeds. Render via `Canvas` with a `TimelineView` driving position updates. Particles follow simple linear motion with opacity decay.

**Progress driving**: `collectProgress` is driven by a `TimelineView(.animation)` timer (not `withAnimation`), incrementing from 0→1 over 1 second while `isPressing` is true. This makes progress a discrete, observable value rather than an interpolated animation — required for both the haptic ramp and the particle spiral-in to track real progress.

**Haptic ramp**: Track which thresholds (0.25, 0.5, 0.75, 1.0) have been crossed using a `@State var lastHapticThreshold: Double`. On each `TimelineView` tick, check if `collectProgress` crossed a new threshold and fire the appropriate `UIImpactFeedbackGenerator`.

### Files changed

- `YouAreDoingGreat/Features/Praise/Views/Components/SparksDisplayView.swift` — full rewrite

### Files unchanged

- `PraiseView.swift` — no changes needed, same API
- `PraiseViewModel.swift` — no changes
- `ChapterProgressBar.swift` — out of scope
- `ChapterUnlockedOverlay.swift` — out of scope
