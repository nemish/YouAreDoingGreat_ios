# Design Specification: YOU-5 Nice Button Improvements

## Overview

This document specifies the UI/UX design for the Nice button improvements across PraiseView and MomentDetailSheet, including the new "Hug" interaction and updated button layouts.

---

## Requirements Summary

From Linear ticket YOU-5:
1. **Praise Screen (loading)**: Don't wait for praise - allow "check later" navigation
2. **Praise Screen (loaded)**: Nice button + Hug button
3. **Replace "Like/Favorite"**: Use "Hug" instead (warmer, more supportive)
4. **Moment Detail Modal**: Nice button + Hug button + Delete button
5. **Layout rule**: Nice fills remaining row width; Hug and Delete are icon-width only

---

## Design Decisions

### 1. "Hug" vs "Favorite/Like"

**Rationale**: The app's tone is warm and supportive ("You Are Doing Great"). "Hug" aligns better with this emotional vocabulary than the transactional "Favorite" or social-media-derived "Like".

**Icon Selection**: `heart.fill` (hugged) / `heart` (not hugged)
- Alternative considered: `hands.clap`, `hand.thumbsup`, `sparkles`
- Heart chosen for universal warmth recognition while being distinct from typical "like"

**Terminology**:
- Action: "Hug" / "Unhug"
- State: `isHugged` (maps to existing `isFavorite` backend field)
- Accessibility: "Give this moment a hug" / "Remove hug from moment"

### 2. Button Layout Pattern

```
┌─────────────────────────────────────────────────┐
│ [        Nice (flex-grow)        ] [Hug] [Del] │
└─────────────────────────────────────────────────┘
```

**Specifications**:
- Nice button: `frame(maxWidth: .infinity)` - fills remaining space
- Hug button: Fixed width (44pt minimum touch target)
- Delete button: Fixed width (44pt minimum touch target)
- Spacing: 12pt between buttons
- Total padding: 24pt horizontal

### 3. Nice Button Behavior Changes

**Current**: Disabled during Phase 1 (POST /moments)
**New**: Always enabled once animations complete

**Navigation on tap**:
- Highlights the moment in MomentsList
- Switches to Moments tab
- Dismisses praise view
- Polling continues in background (unchanged)

---

## Component Specifications

### A. ActionButtonRow (New Shared Component)

**Location**: `YouAreDoingGreat/UI/Components/ActionButtonRow.swift`

```swift
struct ActionButtonRow: View {
    // Configuration
    let primaryTitle: String           // "Nice"
    let isHugged: Bool
    let showDelete: Bool               // false for PraiseView

    // Actions
    let onPrimary: () -> Void
    let onHug: () -> Void
    let onDelete: (() -> Void)?

    // State
    let isPrimaryDisabled: Bool        // For loading states
}
```

**Layout**:
```
HStack(spacing: 12) {
    // Nice button (primary) - fills space
    PrimaryButton(title: primaryTitle, action: onPrimary)
        .disabled(isPrimaryDisabled)

    // Hug button - fixed width
    IconActionButton(
        icon: isHugged ? "heart.fill" : "heart",
        tint: isHugged ? .pink : .textSecondary,
        action: onHug
    )

    // Delete button - fixed width (optional)
    if showDelete, let onDelete {
        IconActionButton(
            icon: "trash",
            tint: .red,
            action: onDelete
        )
    }
}
```

### B. IconActionButton (New Component)

**Location**: `YouAreDoingGreat/UI/Components/IconActionButton.swift`

```swift
struct IconActionButton: View {
    let icon: String                  // SF Symbol name
    var tint: Color = .textSecondary
    var backgroundColor: Color = .white.opacity(0.08)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

**Specifications**:
- Touch target: 48x48pt (exceeds 44pt minimum)
- Icon size: 18pt
- Corner radius: 12pt (matches PrimaryButton)
- Background: `white.opacity(0.08)` (matches existing dark theme)

### C. PraiseView Updates

**File**: `YouAreDoingGreat/Features/Praise/Views/PraiseView.swift`

**Current bottom section** (lines 164-182):
```swift
PrimaryButton(title: "Nice") { ... }
    .disabled(viewModel.isNiceButtonDisabled)
```

**New bottom section**:
```swift
ActionButtonRow(
    primaryTitle: "Nice",
    isHugged: viewModel.isHugged,
    showDelete: false,
    onPrimary: {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        highlightService.highlightMoment(viewModel.clientId)
        selectedTab = 1
        onDismiss()
    },
    onHug: {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task { await viewModel.toggleHug() }
    },
    onDelete: nil,
    isPrimaryDisabled: false  // Always enabled now
)
```

**ViewModel additions** (PraiseViewModelProtocol):
```swift
var isHugged: Bool { get set }
func toggleHug() async
```

### D. MomentDetailSheet Updates

**File**: `YouAreDoingGreat/Features/MomentsList/Views/MomentDetailSheet.swift`

**Current actionButtons** (lines 216-254):
- HStack with Favorite and Delete buttons (50/50 width)

**New actionButtons**:
```swift
private var actionButtons: some View {
    ActionButtonRow(
        primaryTitle: "Nice",
        isHugged: moment.isFavorite,  // Maps to existing field
        showDelete: true,
        onPrimary: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()  // Just close the modal
        },
        onHug: {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            Task { await viewModel.toggleFavorite() }
        },
        onDelete: {
            Task {
                await viewModel.deleteMoment()
                dismiss()
            }
        },
        isPrimaryDisabled: false
    )
}
```

---

## Visual Design

### Color Palette (existing)

| Element | Color | Usage |
|---------|-------|-------|
| Primary Button | `LinearGradient.primaryButton` | Nice button fill |
| Icon Default | `.textSecondary` | Unhug, Delete icons |
| Hug Active | `.pink` / `Color(red: 1, green: 0.4, blue: 0.5)` | Hugged heart |
| Delete | `.red` | Trash icon |
| Button Background | `white.opacity(0.08)` | Icon button background |

### Animation Specifications

**Hug toggle**:
```swift
withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
    // Scale bounce on heart
}
```

**Button press** (existing ScaleButtonStyle):
- Scale: 0.96x on press
- Duration: 0.2s ease-in-out

### Haptic Feedback

| Action | Haptic Style |
|--------|--------------|
| Nice tap | `.light` |
| Hug tap | `.light` |
| Delete tap | `.medium` (destructive) |

---

## State Management

### PraiseViewModel Changes

```swift
// Add to protocol
var isHugged: Bool { get set }
func toggleHug() async

// Implementation
var isHugged: Bool = false

func toggleHug() async {
    guard let moment = localMoment else { return }

    // Optimistic update
    isHugged.toggle()
    moment.isFavorite = isHugged

    do {
        try await repository.update(moment)
        // If synced, also update server
        if let serverId = moment.serverId {
            try await apiClient.request(
                endpoint: .updateMoment(id: serverId),
                method: .patch,
                body: UpdateMomentRequest(isFavorite: isHugged)
            )
        }
    } catch {
        // Revert on failure
        isHugged.toggle()
        moment.isFavorite = isHugged
    }
}
```

### MomentDetailViewModel

**Existing** `toggleFavorite()` - rename for clarity:
- Internal implementation stays the same
- Maps `isFavorite` to "hug" terminology in UI only

---

## Accessibility

### VoiceOver Labels

| Element | Label | Hint |
|---------|-------|------|
| Nice button | "Nice" | "Navigates to moments list" |
| Hug button (off) | "Hug this moment" | "Double tap to give this moment a hug" |
| Hug button (on) | "Remove hug" | "Double tap to remove hug from this moment" |
| Delete button | "Delete moment" | "Double tap to delete this moment" |

### Implementation

```swift
IconActionButton(icon: isHugged ? "heart.fill" : "heart", ...)
    .accessibilityLabel(isHugged ? "Remove hug" : "Hug this moment")
    .accessibilityHint(isHugged
        ? "Double tap to remove hug from this moment"
        : "Double tap to give this moment a hug")
```

---

## Implementation Checklist

### New Files
- [ ] `YouAreDoingGreat/UI/Components/IconActionButton.swift`
- [ ] `YouAreDoingGreat/UI/Components/ActionButtonRow.swift`

### Modified Files
- [ ] `YouAreDoingGreat/Features/Praise/Views/PraiseView.swift`
  - Replace bottom button with ActionButtonRow
  - Remove `isNiceButtonDisabled` dependency
- [ ] `YouAreDoingGreat/Features/Praise/ViewModels/PraiseViewModel.swift`
  - Add `isHugged` property
  - Add `toggleHug()` method
- [ ] `YouAreDoingGreat/Features/Praise/Views/PraiseView.swift` (Protocol)
  - Add `isHugged` and `toggleHug()` to protocol
- [ ] `YouAreDoingGreat/Features/MomentsList/Views/MomentDetailSheet.swift`
  - Replace actionButtons with ActionButtonRow
  - Update copy from "Favorite" to terminology via hug iconography

### Testing Scenarios
1. PraiseView: Tap Nice while praise loading → navigates correctly
2. PraiseView: Tap Hug → heart fills, persists after dismiss
3. MomentDetailSheet: Tap Nice → dismisses modal
4. MomentDetailSheet: Tap Hug → toggles, sheet stays open
5. MomentDetailSheet: Tap Delete → deletes and dismisses
6. Offline: Hug persists locally, syncs when online
7. VoiceOver: All buttons correctly announced

---

## Open Questions for Implementation

1. **Nice button on MomentDetailSheet**: Currently spec says "Nice" dismisses. Should it do anything else (e.g., navigate to a specific moment, show a small celebration animation)?

2. **Hug animation**: Should the heart have a small particle/sparkle effect on toggle, or keep it minimal with just color change?

3. **Delete confirmation**: Current implementation deletes immediately. Should we add a confirmation dialog for destructive action?

---

## Related Files Reference

| Purpose | Path |
|---------|------|
| PraiseView | `Features/Praise/Views/PraiseView.swift` |
| PraiseViewModel | `Features/Praise/ViewModels/PraiseViewModel.swift` |
| MomentDetailSheet | `Features/MomentsList/Views/MomentDetailSheet.swift` |
| MomentDetailViewModel | `Features/MomentsList/ViewModels/MomentDetailViewModel.swift` |
| PrimaryButton | `UI/Components/PrimaryButton.swift` |
| Moment Model | `Core/Models/Moment.swift` |
| Color Extensions | `Core/Extensions/Color+Extensions.swift` |
