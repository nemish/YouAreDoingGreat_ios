# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

"You Are Doing Great" is a React Native mobile app built with Expo that helps users track positive moments in their daily lives. The app features a dynamic UI that changes based on time of day, uses cursor-based pagination for infinite scrolling, and integrates RevenueCat for subscription management.

## Development Commands

### Running the App
```bash
# Start Expo dev server
npm start

# Run on specific platforms
npm run android    # Android emulator
npm run ios        # iOS simulator
npm run web        # Web browser
```

### Code Quality
```bash
npm run lint          # Run ESLint
npm run lint:fix      # Auto-fix linting issues
npm run type-check    # Run TypeScript type checking
```

### EAS Build Commands
```bash
# Development builds
eas build --profile development --platform ios
eas build --profile ios-simulator --platform ios

# Preview builds
eas build --profile preview --platform ios
eas build --profile preview --platform android

# Production builds
eas build --profile production --platform ios
eas build --profile production --platform android
```

## Architecture

### Routing & Navigation

This app uses **Expo Router** (file-based routing):
- `app/_layout.tsx` - Root layout with providers (QueryClient, ThemeProvider, GestureHandlerRootView)
- `app/(tabs)/_layout.tsx` - Tab navigation layout
- `app/(tabs)/index.tsx` - Home screen (renders DashboardPanel)
- `app/(tabs)/profile.tsx` - Profile screen

The app uses React Navigation's dark theme with custom colors defined in `app/_layout.tsx:24-34`.

### State Management

The app uses **Zustand** for state management with multiple focused stores:

- `useMainPanelStore` - Controls main panel states (`init`, `paywall`, `submitForm`, `submittingProgress`, `momentSubmitted`)
- `useUserIdStore` - Manages user ID from secure storage
- `useModalStore` - Controls modal visibility and content
- `useMenuStore` - Manages bottom menu state
- `useHighlightedItem` - Tracks highlighted/selected items

Each store is located in `hooks/stores/`.

### Data Fetching

**TanStack Query (React Query)** is used for all API operations:

- `useCurrentUserQuery` - Fetches current user profile
- `useUserStatsQuery` - Fetches user statistics
- `useFetchApi` - Core API fetch hook that automatically adds `x-user-id` header
- API base URL is configured via environment variables in `eas.json`

The app uses cursor-based pagination for moments list (see API_SPECIFICATION.md for details).

### Component Architecture

Components are organized in a feature-based structure:

```
components/
  features/
    HomeScreen/
      DashboardPanel/          # Main dashboard with moments list
      InitMomentPanel/         # Initial state panel
      SubmitMomentPanel/       # Form for submitting moments
      MomentSubmittedPanel/    # Success state after submission
      SubmittingProgressPanel/ # Loading state during submission
      Paywall/                 # Subscription paywall
    ProfilePanel/              # User profile and settings
    Modals/                    # Modal components (MomentModal, etc.)
  ui/                          # Reusable UI components
    CommonText/                # Text with Comfortaa/PatrickHand fonts
    FancyButton/               # Animated button component
    BackgroundFX/              # Background effects (Lottie, Rive)
    CometAnimation/            # Comet animation effects
```

### Custom Hooks

Important hooks located in `hooks/`:

- `useTimeOfDayElements` - Returns time-based UI elements (greeting, colors, styles)
- `useInitUserId` - Initializes user ID from secure storage on app start
- `useRevenueCat` - Initializes RevenueCat SDK for subscriptions
- `useFavoriteMoment` - Mutation for toggling favorite status
- `useRestorePurchases` - Restores user's subscription purchases

### Type System

**IMPORTANT**: This project uses **types exclusively - NO interfaces**. See AGENTS.md for comprehensive TypeScript guidelines.

Quick rules:
- Always use `type` for all definitions
- Use intersection types (`&`) instead of `extends`
- Use explicit type definitions instead of inline types
- Define types close to their usage

Main types are in `constants/types.ts`.

### Styling

The app uses **NativeWind (Tailwind CSS)** for all styling:
- No StyleSheet.create() - use className instead
- Single dark theme throughout the app
- Always use `CommonText` instead of `Text` for font consistency
- `CommonText` supports `type="playfull"` for PatrickHand font

### Animation

**Always use Moti or React Native Reanimated** for animations:
- Moti for declarative animations (buttons, simple UI)
- Reanimated for complex animations
- Never use the deprecated Animated API

Background effects use:
- Lottie for JSON animations
- Rive for .riv animations
- Skia for advanced graphics (comets)

### Time-Based UI

The app adapts its UI based on time of day using `useTimeOfDayElements`:
- Morning (6-12): Light colors, energetic feel
- Afternoon (12-17): Warm colors
- Evening (17-22): Calm, relaxing colors
- Night (22-6): Dark, peaceful colors

This affects greetings, background colors, and overall theme.

## API Integration

### Authentication

All API requests require the `x-user-id` header. This is automatically added by the `useFetchApi` hook.

### Environment Variables

API URLs are configured per environment in `eas.json`:
- **Development**: `http://localhost:3000`
- **Preview**: `https://1test1.xyz`
- **Production**: `https://api.you-are-doing-great.com`

Access via: `process.env.EXPO_PUBLIC_API_URL`

### API Endpoints

See `API_SPECIFICATION.md` for complete API documentation. Key endpoints:

- `GET /api/v1/user/me` - Get current user
- `GET /api/v1/moments?cursor={cursor}&limit={limit}` - Get moments (paginated)
- `POST /api/v1/moments` - Create moment
- `PUT /api/v1/moments/{id}` - Update moment (favorite status)
- `DELETE /api/v1/moments/{id}` - Archive moment

### Updating API Specs

When the backend API changes, run:
```bash
curl -s http://localhost:3000/docs/as_json > spec.json
```

Then update `API_SPECIFICATION.md` following the guidelines in AGENTS.md (lines 1526-1583).

## Form Handling

**Always use react-hook-form** for all forms:
- Use `Controller` component for form fields
- Implement validation rules in the `rules` prop
- Handle submission with `handleSubmit`
- Display errors from `formState.errors`

See AGENTS.md (lines 694-1174) for comprehensive form handling guidelines.

## Subscription Management

The app uses **RevenueCat** for subscription management:
- SDK initialized in `useRevenueCat` hook
- API key configured in `eas.json` via `EXPO_PUBLIC_REVENUECAT_API_KEY`
- Paywall shown when user status is `paywall_needed`
- User status: `newcomer` | `paywall_needed` | `premium`

## Import Paths

The project uses `@/` alias for absolute imports (configured in `tsconfig.json`):

```typescript
// ✅ Good: Use @ alias for deep imports
import { Component } from "@/components/features/Feature";
import { useHook } from "@/hooks/useHook";

// ✅ Good: Use relative for nearby files
import { Sub } from "./SubComponent";
import { Parent } from "../Parent";

// ❌ Bad: Deep relative paths
import { Component } from "../../../features/Component";
```

## Key Development Patterns

### Panel State Flow

The home screen uses a state machine pattern via `useMainPanelStore`:
1. `init` - Initial empty state
2. User taps "Add Moment" → `submitForm`
3. Submit pressed → `submittingProgress`
4. Success → `momentSubmitted`
5. Or if not premium → `paywall`

### Moments List Pattern

Uses React Query's `useInfiniteQuery` with cursor-based pagination:
```typescript
const { data, fetchNextPage, hasNextPage } = useInfiniteQuery({
  queryKey: ["moments"],
  queryFn: ({ pageParam }) => fetchMoments(pageParam),
  getNextPageParam: (lastPage) => lastPage.nextCursor,
  initialPageParam: undefined,
});
```

### User Initialization Flow

On app start (in `app/_layout.tsx`):
1. `useInitUserId` loads user ID from SecureStore
2. `useRevenueCat` initializes subscription SDK
3. Wait for fonts + userId before showing UI
4. Hide splash screen once ready

## Important Files

- `AGENTS.md` - Comprehensive development guidelines (TypeScript, API, forms, styling)
- `API_SPECIFICATION.md` - Complete API contract documentation
- `app/_layout.tsx` - Root layout with all providers
- `hooks/useFetchApi/index.ts` - Core API client
- `constants/types.ts` - Shared type definitions
- `eas.json` - Build configuration and environment variables

## Testing

Currently no test configuration. When adding tests:
- Use React Native Testing Library for components
- Use jest for unit tests
- Test API hooks with MSW for mocking
