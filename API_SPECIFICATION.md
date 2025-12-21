# You Are Doing Great API - Client Contract Specification

## Overview

This document provides the API contract specification for the "You Are Doing Great" application, which manages user moments and user profiles with cursor-based pagination for infinite scrolling. This specification is designed for client-side developers to understand the API interface and implement proper data fetching and state management.

## Base URL

```
http://localhost:3000/api/v1
```

## API Information

- **Title**: You Are Doing Great API
- **Description**: API for managing user moments and user profiles with cursor-based pagination
- **Version**: 1.0.0
- **Contact**: support@example.com

## Authentication

The API uses a dual authentication system:

### 1. App Token (Required for all endpoints except /health)

All API endpoints require an app token via the `x-app-token-code` header:

```
x-app-token-code: <app_token>
```

This validates that requests come from authorized applications.

### 2. User Authentication (Required for protected endpoints)

User-specific endpoints also require the `x-user-id` header:

```
x-user-id: <user_id>
```

### Request Headers Example

```
x-app-token-code: your-app-token
x-user-id: user-123
Content-Type: application/json
```

## Key Changes in Latest Version

### Timeline Restriction (Premium Feature) - Simplified Response

Free users can only access data from the last 14 days. Premium users have unlimited access to their full history.

**New behavior**: Instead of returning a 403 error, the API now:
- Filters out data older than 14 days for free users
- Sets `limitReached: true` in paginated responses when older data exists
- Individual moment endpoints (`/moments/{id}`, `/moments/by-client-id/{clientId}`) have **no timeline restriction**

**Affected endpoints**: `/moments`, `/timeline`
**Response field**: `limitReached` boolean in paginated responses

### App Token Authentication

All endpoints now require `x-app-token-code` header for API access validation (except `/health`).

### Enhanced Health Check

The `/health` endpoint now returns MongoDB connection status and does NOT require app token authentication.

### Error Codes

- `UNAUTHORIZED`: Missing or invalid authentication
- `RESTRICTED_ACCESS`: User does not have access to resource
- `INTERNAL_SERVER_ERROR`: Server error
- `DAILY_LIMIT_REACHED`: User has reached their daily moment limit
- `INVALID_CURSOR`: Invalid pagination cursor
- `MOMENT_NOT_FOUND`: Moment not found
- `FORBIDDEN`: User does not own this resource
- `INVALID_REQUEST`: Invalid request parameters
- `ENRICHMENT_IN_PROGRESS`: AI enrichment is already being processed for this moment
- `INVALID_APP_TOKEN`: Missing or invalid app token
- `INVALID_WEBHOOK_AUTH`: Invalid or missing webhook auth
- `VALIDATION_ERROR`: Request validation failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `CONFLICT`: Resource conflict

### Offline Sync Support

The API supports offline-first clients with the following features:

1. **Client ID Support**: Moments can include a `clientId` (UUID) for offline sync correlation
2. **Lookup by Client ID**: Endpoint `GET /moments/by-client-id/{clientId}` for finding moments by client-generated ID
3. **Separated Enrichment**: Moment creation (`POST /moments`) and AI enrichment (`POST /moments/{id}/enrich`) are separate operations

### Two-Phase Moment Creation

1. **Phase 1 - Create**: `POST /moments` creates moment immediately without AI processing (fast return)
2. **Phase 2 - Enrich**: `POST /moments/{id}/enrich` adds AI-generated praise, tags, and action category (async, can be polled)

This allows clients to:
- Save moments locally with client-generated UUID
- Submit to server and get server ID back immediately
- Poll for AI enrichment completion without blocking user

## Endpoints

### 1. Health Check

**GET** `/health`

Health check endpoint for monitoring. This endpoint does NOT require app token authentication. Returns MongoDB connection status and overall API health.

#### Response (200 - Healthy)

```json
{
  "status": "ok",
  "checks": {
    "mongodb": "connected"
  }
}
```

#### Response (503 - Degraded)

```json
{
  "status": "degraded",
  "checks": {
    "mongodb": "disconnected"
  }
}
```

### 2. Get Current User Profile

**GET** `/user/me`

Retrieve the current user's profile information.

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "user_123",
    "userId": "auth0|123456789",
    "status": "free"
  }
}
```

#### Response Fields

- `item`: User object containing:
  - `id`: Unique identifier for the user
  - `userId`: External user ID from authentication system
  - `status`: User subscription status (`free`, `premium`)

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 3. Get User Statistics

**GET** `/user/stats`

Retrieve statistics about user's moment submissions including streaks and totals.

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "userId": "auth0|123456789",
    "totalMoments": 150,
    "momentsToday": 2,
    "momentsYesterday": 3,
    "currentStreak": 7,
    "longestStreak": 30,
    "lastMomentDate": "2024-01-15T10:30:00Z"
  }
}
```

#### Response Fields

- `item`: User statistics object containing:
  - `userId`: External user ID from authentication system
  - `totalMoments`: Total number of moments submitted by the user
  - `momentsToday`: Number of moments submitted today
  - `momentsYesterday`: Number of moments submitted yesterday
  - `currentStreak`: Current consecutive days streak
  - `longestStreak`: Longest consecutive days streak ever achieved
  - `lastMomentDate`: Timestamp of the last submitted moment (ISO date-time, nullable)

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 4. Submit User Feedback

**POST** `/user/feedback`

Submit feedback from the user including title and description.

#### Request Headers

```
Content-Type: application/json
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Request Body

```json
{
  "title": "Feature request",
  "text": "It would be great if the app had..."
}
```

#### Request Fields

- `title` (required): Title of the feedback (1-200 characters)
- `text` (required): Detailed feedback text (1-5000 characters)

#### Response

```json
{
  "item": {
    "id": "feedback_123",
    "title": "Feature request",
    "text": "It would be great if the app had...",
    "createdAt": "2024-01-15T10:30:00Z"
  }
}
```

#### Error Responses

- `400 Bad Request`: Invalid request body
- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 5. Get Moments with Pagination

**GET** `/moments`

Retrieve user moments with cursor-based pagination for infinite scrolling.

**Timeline Restriction:** Free users can only access data from the last 14 days. Data older than 14 days is filtered out and `limitReached` is set to true. Premium users have unlimited access to their full history.

#### Query Parameters

- `cursor` (optional): Timestamp cursor for pagination (ISO date-time format)
- `limit` (optional): Number of items per page (1-100, default: 20)

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "data": [
    {
      "id": "moment_123",
      "clientId": "550e8400-e29b-41d4-a716-446655440000",
      "text": "Today was amazing!",
      "submittedAt": "2024-01-15T10:30:00Z",
      "happenedAt": "2024-01-15T09:30:00Z",
      "tz": "America/New_York",
      "action": "exercise",
      "tags": ["milestone", "writing", "streak"],
      "praise": "Great job! You're making amazing progress!",
      "isFavorite": false,
      "timeAgo": 3600
    }
  ],
  "nextCursor": "2024-01-15T10:30:00Z",
  "hasNextPage": true,
  "limitReached": false
}
```

#### Response Fields

- `data`: Array of moment objects
- `nextCursor`: Cursor for the next page (timestamp, null if no more pages)
- `hasNextPage`: Boolean indicating if there are more pages
- `limitReached`: Boolean indicating if the user has reached their timeline limit (true for free users when older data exists, always false for premium)

#### Error Responses

- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 6. Get a Specific Moment

**GET** `/moments/{id}`

Retrieve a specific moment by server ID.

**No timeline restriction applies when fetching individual moments.**

#### Path Parameters

- `id`: Server-generated moment ID

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "clientId": "550e8400-e29b-41d4-a716-446655440000",
    "text": "Today was amazing!",
    "submittedAt": "2024-01-15T10:30:00Z",
    "happenedAt": "2024-01-15T09:30:00Z",
    "tz": "America/New_York",
    "action": "exercise",
    "tags": ["milestone", "writing", "streak"],
    "praise": "Great job! You're making amazing progress!",
    "isFavorite": false,
    "timeAgo": 3600
  }
}
```

#### Response Fields

- `item`: Moment object

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `403 Forbidden`: User does not own this moment (FORBIDDEN)
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 7. Get Moment by Client ID

**GET** `/moments/by-client-id/{clientId}`

Retrieve a specific moment by its client-generated UUID. This endpoint is essential for offline sync correlation.

**No timeline restriction applies when fetching individual moments.**

#### Path Parameters

- `clientId`: Client-generated UUID (format: `550e8400-e29b-41d4-a716-446655440000`)

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "clientId": "550e8400-e29b-41d4-a716-446655440000",
    "text": "Today was amazing!",
    "submittedAt": "2024-01-15T10:30:00Z",
    "happenedAt": "2024-01-15T09:30:00Z",
    "tz": "America/New_York",
    "action": null,
    "tags": null,
    "praise": null,
    "isFavorite": false,
    "timeAgo": 3600
  }
}
```

#### Use Cases

- **Offline Sync**: Client creates moment offline with UUID, later finds it on server using this endpoint
- **Correlation**: Match local moment with server moment after sync
- **Status Check**: Poll to see if moment has been enriched with AI content

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `403 Forbidden`: User does not own this moment (FORBIDDEN)
- `404 Not Found`: Moment with this clientId not found
- `500 Internal Server Error`: Server error

### 8. Create a New Moment

**POST** `/moments`

Create a moment record in the database **without AI processing**. The moment is created immediately with null/undefined action, tags, and praise. Use `POST /moments/{id}/enrich` to add AI-generated content.

This endpoint now returns immediately, making it suitable for offline-first apps that need fast responses.

#### Request Headers

```
Content-Type: application/json
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Request Body

```json
{
  "clientId": "550e8400-e29b-41d4-a716-446655440000",
  "text": "New moment text",
  "submittedAt": "2024-01-15T10:30:00Z",
  "tz": "America/New_York",
  "timeAgo": 3600
}
```

#### Request Fields

- `clientId` (optional): Client-generated UUID for offline sync correlation. Server echoes this back in response.
- `text` (required): The moment text content (1-1000 characters)
- `submittedAt` (optional): When the moment was submitted (defaults to current time)
- `tz` (optional): Timezone of the user
- `timeAgo` (optional): Seconds passed from when the moment actually happened to when it was submitted

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "clientId": "550e8400-e29b-41d4-a716-446655440000",
    "text": "New moment text",
    "submittedAt": "2024-01-15T10:30:00Z",
    "happenedAt": "2024-01-15T09:30:00Z",
    "tz": "America/New_York",
    "action": null,
    "tags": null,
    "praise": null,
    "isFavorite": false,
    "timeAgo": 3600
  }
}
```

**Note**: `action`, `tags`, and `praise` will be `null` until enrichment is performed.

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 9. Enrich Moment with AI Content

**POST** `/moments/{id}/enrich`

Add AI-generated action category, tags, and praise to an existing moment. This endpoint is **idempotent** - if the moment is already enriched, it returns the existing data without calling the AI again. Daily limits are checked before processing.

#### Path Parameters

- `id`: Server-generated moment ID to enrich

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "clientId": "550e8400-e29b-41d4-a716-446655440000",
    "text": "New moment text",
    "submittedAt": "2024-01-15T10:30:00Z",
    "happenedAt": "2024-01-15T09:30:00Z",
    "tz": "America/New_York",
    "action": "exercise",
    "tags": ["milestone", "writing", "streak"],
    "praise": "Great job! You're making amazing progress!",
    "isFavorite": false,
    "timeAgo": 3600
  }
}
```

#### Client Implementation Pattern

```typescript
// 1. Create moment (fast, no AI)
const created = await POST('/moments', { text, clientId });

// 2. Poll for enrichment (async, can be in background)
let enriched = created;
while (!enriched.praise) {
  await sleep(3000);
  enriched = await POST(`/moments/${created.id}/enrich`);
}
```

#### Error Responses

- `400 Bad Request`: Daily limit reached
- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `409 Conflict`: Enrichment already in progress
- `500 Internal Server Error`: Server error

### 10. Update a Moment

**PUT** `/moments/{id}`

Update a specific moment (currently supports updating favorite status).

#### Path Parameters

- `id`: Moment ID

#### Request Headers

```
Content-Type: application/json
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Request Body

```json
{
  "isFavorite": true
}
```

#### Request Fields

- `isFavorite` (required): Whether to mark the moment as favorite

#### Response

```json
{
  "message": "Moment updated"
}
```

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 11. Archive a Moment

**DELETE** `/moments/{id}`

Soft delete a moment by setting archivedAt timestamp.

#### Path Parameters

- `id`: Moment ID

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "message": "Moment archived"
}
```

#### Error Responses

- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 12. Get Timeline with Pagination

**GET** `/timeline`

Retrieve user day summaries with cursor-based pagination for infinite scrolling timeline.

**Timeline Restriction:** Free users can only access data from the last 14 days. Data older than 14 days is filtered out and `limitReached` is set to true. Premium users have unlimited access to their full history.

#### Query Parameters

- `cursor` (optional): Date cursor for pagination (ISO date-time format)
- `limit` (optional): Number of items per page (1-100, default: 20)

#### Request Headers

```
x-app-token-code: <app_token>
x-user-id: <user_id>
```

#### Response

```json
{
  "data": [
    {
      "id": "summary_123",
      "date": "2024-01-15T00:00:00Z",
      "text": "You had a productive day with 5 workouts and quality family time!",
      "tags": ["exercise", "mindfulness", "productivity"],
      "momentsCount": 12,
      "timesOfDay": ["cloud-sun", "sun-medium", "sunset"],
      "state": "FINALISED",
      "createdAt": "2024-01-16T02:00:00Z"
    }
  ],
  "nextCursor": "2024-01-15T00:00:00Z",
  "hasNextPage": true,
  "limitReached": false
}
```

#### Response Fields

- `data`: Array of day summary objects
- `nextCursor`: Date cursor for the next page (null if no more pages)
- `hasNextPage`: Boolean indicating if there are more pages
- `limitReached`: Boolean indicating if the user has reached their timeline limit (true for free users when older data exists, always false for premium)

**Day Summary Object:**

- `id`: Unique identifier for the day summary
- `date`: The date this summary represents (start of day, ISO date-time)
- `text`: AI-generated summary text (null if INPROGRESS or no moments for this day)
- `tags`: Top 5 most popular tags from moments on this day
- `momentsCount`: Total number of moments logged on this day
- `timesOfDay`: Array of time periods when moments were logged:
  - `sunrise`: 5-8am
  - `cloud-sun`: 8am-12pm
  - `sun-medium`: 12-5pm
  - `sunset`: 5-8pm
  - `moon`: night
- `state`: Processing state of the day summary:
  - `INPROGRESS`: Day is ongoing, AI summary not yet generated
  - `FINALISED`: Summary is complete with AI-generated text
- `createdAt`: When the summary was created (ISO date-time)

#### Error Responses

- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Invalid or missing app token (INVALID_APP_TOKEN) or user ID (RESTRICTED_ACCESS)
- `500 Internal Server Error`: Server error

### 13. RevenueCat Webhook

**POST** `/webhooks/revenuecat`

Webhook endpoint for RevenueCat subscription events. Updates user subscription status based on purchase, renewal, and expiration events.

**Authentication:** Requires `Authorization` header with RevenueCat webhook secret. Does NOT use x-app-token-code or x-user-id headers.

#### Events that grant premium status:
- INITIAL_PURCHASE
- RENEWAL
- UNCANCELLATION
- SUBSCRIPTION_EXTENDED

#### Events that revoke premium status:
- EXPIRATION

#### Events logged but no status change:
- CANCELLATION (user keeps access until expiration)
- BILLING_ISSUE (grace period)
- PRODUCT_CHANGE
- SUBSCRIPTION_PAUSED
- TRANSFER
- TEST

#### Request Body

```json
{
  "api_version": "1.0",
  "event": {
    "type": "INITIAL_PURCHASE",
    "id": "event_123456",
    "app_user_id": "user_123",
    "original_app_user_id": "user_123",
    "product_id": "premium_monthly",
    "entitlement_ids": ["premium"],
    "expiration_at_ms": 1704067200000,
    "store": "APP_STORE"
  }
}
```

#### Response

```json
{
  "received": true
}
```

#### Error Responses

- `400 Bad Request`: Invalid payload
- `401 Unauthorized`: Invalid or missing webhook auth

## Data Models

### User

```json
{
  "id": "string",
  "userId": "string",
  "status": "free" | "premium"
}
```

### Moment

```json
{
  "id": "string",
  "clientId": "string (UUID) | null",
  "text": "string",
  "submittedAt": "string (ISO date-time)",
  "happenedAt": "string (ISO date-time)",
  "tz": "string",
  "action": "string | null",
  "tags": "string[] | null",
  "praise": "string | null",
  "isFavorite": "boolean",
  "timeAgo": "integer | null"
}
```

**Required Fields:**

- `id`: Server-generated unique identifier for the moment
- `text`: The moment text content
- `submittedAt`: When the moment was submitted (ISO date-time)
- `happenedAt`: When the moment actually happened (calculated as submittedAt - timeAgo, ISO date-time)
- `tz`: Timezone of the user

**Optional Fields:**

- `clientId`: Client-generated UUID for offline sync correlation (null if not provided)
- `action`: Normalized action category (null until enriched)
- `tags`: Tags extracted from the moment (null/empty until enriched, e.g., ["milestone", "writing", "streak"])
- `praise`: AI-generated praise message (null until enriched)
- `isFavorite`: Whether the moment is marked as favorite
- `timeAgo`: Seconds passed from when the moment actually happened to when it was submitted (null if not specified)

### CreateMomentRequest

```json
{
  "clientId": "string (UUID, optional)",
  "text": "string (1-1000 characters)",
  "submittedAt": "string (ISO date-time, optional)",
  "tz": "string (optional)",
  "timeAgo": "integer (optional, nullable)"
}
```

**Fields:**

- `clientId` (optional): Client-generated UUID for offline sync correlation
- `text` (required): The moment text content (1-1000 characters)
- `submittedAt` (optional): When the moment was submitted (defaults to current time)
- `tz` (optional): Timezone of the user
- `timeAgo` (optional, nullable): Seconds passed from when the moment actually happened to when it was submitted

### UpdateMomentRequest

```json
{
  "isFavorite": "boolean"
}
```

### PaginatedMomentsResponse

```json
{
  "data": "Moment[]",
  "nextCursor": "string (ISO date-time) | null",
  "hasNextPage": "boolean",
  "limitReached": "boolean"
}
```

### PaginatedTimelineResponse

```json
{
  "data": "DaySummary[]",
  "nextCursor": "string (ISO date-time) | null",
  "hasNextPage": "boolean",
  "limitReached": "boolean"
}
```

### CreateMomentResponse

```json
{
  "item": "Moment"
}
```

### GetMomentResponse

```json
{
  "item": "Moment"
}
```

### EnrichMomentResponse

```json
{
  "item": "Moment"
}
```

### UpdateMomentResponse

```json
{
  "message": "string"
}
```

### ArchiveMomentResponse

```json
{
  "message": "string"
}
```

### UserResponse

```json
{
  "item": "User"
}
```

### UserStats

```json
{
  "userId": "string",
  "totalMoments": "integer",
  "momentsToday": "integer",
  "momentsYesterday": "integer",
  "currentStreak": "integer",
  "longestStreak": "integer",
  "lastMomentDate": "string (ISO date-time) | null"
}
```

**Required Fields:**

- `userId`: External user ID from authentication system
- `totalMoments`: Total number of moments submitted by the user
- `momentsToday`: Number of moments submitted today
- `momentsYesterday`: Number of moments submitted yesterday
- `currentStreak`: Current consecutive days streak
- `longestStreak`: Longest consecutive days streak ever achieved

**Optional Fields:**

- `lastMomentDate`: Timestamp of the last submitted moment (null if no moments)

### UserStatsResponse

```json
{
  "item": "UserStats"
}
```

### UserFeedback

```json
{
  "id": "string",
  "title": "string",
  "text": "string",
  "createdAt": "string (ISO date-time)"
}
```

### CreateUserFeedbackRequest

```json
{
  "title": "string (1-200 characters)",
  "text": "string (1-5000 characters)"
}
```

### CreateUserFeedbackResponse

```json
{
  "item": "UserFeedback"
}
```

### DaySummary

```json
{
  "id": "string",
  "date": "string (ISO date-time)",
  "text": "string | null",
  "tags": "string[]",
  "momentsCount": "integer",
  "timesOfDay": "string[]",
  "state": "INPROGRESS | FINALISED",
  "createdAt": "string (ISO date-time)"
}
```

**Required Fields:**

- `id`: Unique identifier for the day summary
- `date`: The date this summary represents (start of day, ISO date-time)
- `tags`: Top 5 most popular tags from moments on this day
- `momentsCount`: Total number of moments logged on this day
- `timesOfDay`: Array of time periods when moments were logged
- `state`: Processing state of the day summary
  - `INPROGRESS`: Day is ongoing, AI summary not yet generated
  - `FINALISED`: Summary is complete with AI-generated text
- `createdAt`: When the summary was created (ISO date-time)

**Optional Fields:**

- `text`: AI-generated summary text (null if INPROGRESS or no moments for this day)

### ErrorResponse

```json
{
  "error": {
    "code": "string",
    "message": "string"
  },
  "meta": "object (optional)"
}
```

**Error Codes:**

- `UNAUTHORIZED`: Missing or invalid authentication
- `RESTRICTED_ACCESS`: User does not have access to resource
- `INTERNAL_SERVER_ERROR`: Server error
- `DAILY_LIMIT_REACHED`: User has reached their daily moment limit
- `INVALID_CURSOR`: Invalid pagination cursor
- `MOMENT_NOT_FOUND`: Moment not found
- `FORBIDDEN`: User does not own this resource
- `INVALID_REQUEST`: Invalid request parameters
- `ENRICHMENT_IN_PROGRESS`: AI enrichment is already being processed for this moment
- `INVALID_APP_TOKEN`: Missing or invalid app token
- `INVALID_WEBHOOK_AUTH`: Invalid or missing webhook auth
- `VALIDATION_ERROR`: Request validation failed
- `RATE_LIMIT_EXCEEDED`: Too many requests
- `CONFLICT`: Resource conflict

**Example:**

```json
{
  "error": {
    "code": "DAILY_LIMIT_REACHED",
    "message": "You've reached your daily limit of 10 moments. Upgrade to premium for 50 moments per day!"
  },
  "meta": {
    "limit": 10,
    "isPremium": false
  }
}
```

## Pagination Strategy

### Cursor-Based Pagination

The API uses cursor-based pagination for efficient infinite scrolling:

- **Cursor**: Timestamp-based cursor using the `submittedAt` field
- **Direction**: Forward-only pagination (newest first)
- **Cursor Value**: ISO date-time string of the last item in the current page
- **Next Page**: Use `nextCursor` from the response to fetch the next page
- **End Condition**: `hasNextPage` is `false` when no more pages are available

### Pagination Flow

1. **Initial Request**: `GET /moments?limit=20` (no cursor)
2. **Next Page**: `GET /moments?cursor=2024-01-15T10:30:00Z&limit=20`
3. **Continue**: Use `nextCursor` from each response until `hasNextPage: false`

### Sorting

- Moments are sorted by `submittedAt` in **descending order** (newest first)
- This ensures the most recent moments appear at the top of the list

### Timeline Restriction Handling

Check the `limitReached` field in paginated responses to determine if the user has restrictions:

```swift
if response.limitReached {
    // User is on free plan and has reached their 14-day limit
    // Show upgrade prompt
}
```

## Offline-First Implementation Guide

### Recommended Sync Flow

1. **Save locally**: Create moment in local storage with client-generated UUID
2. **Show offline praise**: Display instant encouragement from local pool
3. **Submit to server**: POST moment with `clientId` to `/moments`
4. **Save server ID**: Update local moment with returned server `id`
5. **Enrich in background**: POST to `/moments/{id}/enrich` (can be async/polled)
6. **Update UI**: When enrichment completes, update local moment with AI praise/tags

### Handling Disconnected State

If user dismisses before POST completes:

1. Moment remains in local storage with `isSynced: false`
2. Background sync service finds unsynced moments
3. For moments without `serverId`:
   - Try `GET /moments/by-client-id/{clientId}`
   - If 404: POST to create
   - If 200: Save `serverId` and check enrichment status
4. For moments with `serverId` but no praise:
   - POST to `/moments/{id}/enrich`
   - Poll until enriched or max attempts reached

### Example Swift Implementation

```swift
// 1. Save locally with clientId
let moment = Moment(
    clientId: UUID(),
    text: text,
    submittedAt: Date(),
    isSynced: false
)
try await repository.save(moment)

// 2. POST to server
let response = try await POST("/moments", body: {
    clientId: moment.clientId.uuidString,
    text: text
})

// 3. Save serverId
moment.serverId = response.id
try await repository.update(moment)

// 4. Enrich (async, can continue in background)
Task.detached {
    let enriched = try await POST("/moments/\(response.id)/enrich")
    if let praise = enriched.praise {
        moment.praise = praise
        moment.tags = enriched.tags
        moment.isSynced = true
        try await repository.update(moment)
    }
}
```

## Error Handling

### 400 Bad Request

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Text must be between 1 and 1000 characters"
  }
}
```

```json
{
  "error": {
    "code": "DAILY_LIMIT_REACHED",
    "message": "You've reached your daily limit of 10 moments. Upgrade to premium for 50 moments per day!"
  },
  "meta": {
    "limit": 10,
    "isPremium": false
  }
}
```

### 401 Unauthorized

```json
{
  "error": {
    "code": "INVALID_APP_TOKEN",
    "message": "Missing or invalid app token"
  }
}
```

```json
{
  "error": {
    "code": "RESTRICTED_ACCESS",
    "message": "Missing or invalid user ID"
  }
}
```

### 403 Forbidden

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "User does not own this moment"
  }
}
```

### 404 Not Found

```json
{
  "error": {
    "code": "MOMENT_NOT_FOUND",
    "message": "Moment not found"
  }
}
```

### 409 Conflict

```json
{
  "error": {
    "code": "ENRICHMENT_IN_PROGRESS",
    "message": "Enrichment is already in progress for this moment"
  }
}
```

### 429 Too Many Requests

```json
{
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Too many requests. Please try again later."
  }
}
```

### 500 Internal Server Error

```json
{
  "error": {
    "code": "INTERNAL_SERVER_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

## Testing Scenarios

### Test Cases

1. **Initial load**: No cursor, should return first page
2. **Forward pagination**: With cursor, should return next page
3. **Last page**: Should set `hasNextPage` to false
4. **Invalid cursor**: Should return 400 error
5. **Large limit**: Should return 400 if limit > 100
6. **Empty results**: Should return empty data array with `hasNextPage: false`
7. **Client ID lookup**: Should find moment by clientId or return 404
8. **Offline sync**: Create with clientId, dismiss, resume sync by clientId
9. **Enrichment idempotency**: Calling enrich multiple times should not re-process
10. **Ownership**: Should prevent users from accessing others' moments
11. **App token validation**: Should reject requests without valid app token
12. **Rate limiting**: Should return 429 when rate limit exceeded
13. **Timeline restriction (free user)**: Should filter old data and set `limitReached: true`
14. **Timeline restriction (premium user)**: Should allow access to full history with `limitReached: false`
15. **Individual moment access**: Should allow free users to access any moment by ID (no restriction)

### Example Test Sequence

```
1. POST /moments (with clientId)
   -> Returns moment with id, clientId, null praise

2. POST /moments/{id}/enrich
   -> Returns 200 (processing started)

3. Poll POST /moments/{id}/enrich
   -> Returns moment with praise when ready

4. GET /moments/by-client-id/{clientId}
   -> Returns same moment (no timeline restriction)

5. GET /moments?limit=5
   -> Returns first 5 moments, hasNextPage: true, limitReached: false

6. GET /moments?cursor=2024-01-15T10:30:00Z&limit=5
   -> Returns next 5 moments

7. Continue paginating for free user
   -> Eventually returns data with limitReached: true when 14-day boundary reached
```

## Business Rules

### User Status

- **free**: Basic access with timeline restricted to last 14 days in list views
- **premium**: Full access to all features and unlimited history

### Timeline Restriction

- Free users can only access data from the last 14 days in paginated list endpoints
- Premium users have unlimited access to their full history
- Data older than 14 days is filtered (not returned as error)
- `limitReached: true` indicates free user has more data beyond the 14-day window
- Individual moment endpoints (`/moments/{id}`, `/moments/by-client-id/{clientId}`) have no timeline restriction

### Moment Lifecycle

1. **Created**: Moment is submitted without enrichment
2. **Enriched**: AI content (praise, tags, action) is added
3. **Updated**: Favorite status can be toggled
4. **Archived**: Moment is soft-deleted (not permanently removed)
5. **Retrieved**: Only non-archived moments are returned in queries

### Data Validation

- **Text length**: 1-1000 characters
- **Timestamp format**: ISO 8601 date-time strings
- **Timezone**: Standard timezone identifiers (e.g., "America/New_York")
- **Cursor format**: Valid ISO timestamp for pagination
- **Client ID format**: Valid UUID format (e.g., "550e8400-e29b-41d4-a716-446655440000")
