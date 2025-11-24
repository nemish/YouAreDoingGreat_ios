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

All endpoints require authentication via the `x-user-id` header:

```
x-user-id: <user_id>
```

## Endpoints

### 1. Health Check

**GET** `/healthcheck`

Simple health check to verify the API is running.

#### Response

```json
{
  "status": "ok",
  "version": 1
}
```

### 2. Get Current User Profile

**GET** `/user/me`

Retrieve the current user's profile information.

#### Request Headers

```
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "user_123",
    "userId": "auth0|123456789",
    "status": "newcomer"
  }
}
```

#### Response Fields

- `item`: User object containing:
  - `id`: Unique identifier for the user
  - `userId`: External user ID from authentication system
  - `status`: User subscription status (`newcomer`, `paywall_needed`, `premium`)

#### Error Responses

- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

### 3. Get User Statistics

**GET** `/user/stats`

Retrieve statistics about user's moment submissions including streaks and totals.

#### Request Headers

```
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

- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

### 4. Get Moments with Pagination

**GET** `/moments`

Retrieve user moments with cursor-based pagination for infinite scrolling.

#### Query Parameters

- `cursor` (optional): Timestamp cursor for pagination (ISO date-time format)
- `limit` (optional): Number of items per page (1-100, default: 20)

#### Request Headers

```
x-user-id: <user_id>
```

#### Response

```json
{
  "data": [
    {
      "id": "moment_123",
      "text": "Today was amazing!",
      "submittedAt": "2024-01-15T10:30:00Z",
      "tz": "America/New_York",
      "action": "exercise",
      "praise": "Great job! You're making amazing progress!",
      "isFavorite": false,
      "archivedAt": null
    }
  ],
  "nextCursor": "2024-01-15T10:30:00Z",
  "hasNextPage": true
}
```

#### Response Fields

- `data`: Array of moment objects
- `nextCursor`: Cursor for the next page (timestamp, null if no more pages)
- `hasNextPage`: Boolean indicating if there are more pages

#### Error Responses

- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

### 5. Get a Specific Moment

**GET** `/moments/{id}`

Retrieve a specific moment by ID.

#### Path Parameters

- `id`: Moment ID

#### Request Headers

```
x-user-id: <user_id>
```

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "text": "Today was amazing!",
    "submittedAt": "2024-01-15T10:30:00Z",
    "tz": "America/New_York",
    "action": "exercise",
    "praise": "Great job! You're making amazing progress!",
    "isFavorite": false,
    "archivedAt": null
  }
}
```

#### Response Fields

- `item`: Moment object

#### Error Responses

- `401 Unauthorized`: Missing or invalid user ID
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 6. Create a New Moment

**POST** `/moments`

Submit a new moment for the authenticated user.

#### Request Headers

```
Content-Type: application/json
x-user-id: <user_id>
```

#### Request Body

```json
{
  "text": "New moment text",
  "submittedAt": "2024-01-15T10:30:00Z",
  "tz": "America/New_York"
}
```

#### Request Fields

- `text` (required): The moment text content (1-1000 characters)
- `submittedAt` (optional): When the moment was submitted (defaults to current time)
- `tz` (optional): Timezone of the user

#### Response

```json
{
  "item": {
    "id": "moment_123",
    "text": "New moment text",
    "submittedAt": "2024-01-15T10:30:00Z",
    "tz": "America/New_York",
    "action": "exercise",
    "praise": "Great job! You're making amazing progress!",
    "isFavorite": false,
    "archivedAt": null
  }
}
```

#### Error Responses

- `400 Bad Request`: Invalid request body or daily limit reached
- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

### 7. Update a Moment

**PUT** `/moments/{id}`

Update a specific moment (currently supports updating favorite status).

#### Path Parameters

- `id`: Moment ID

#### Request Headers

```
Content-Type: application/json
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

- `401 Unauthorized`: Missing or invalid user ID
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 8. Archive a Moment

**DELETE** `/moments/{id}`

Soft delete a moment by setting archivedAt timestamp.

#### Path Parameters

- `id`: Moment ID

#### Request Headers

```
x-user-id: <user_id>
```

#### Response

```json
{
  "message": "Moment archived"
}
```

#### Error Responses

- `401 Unauthorized`: Missing or invalid user ID
- `403 Forbidden`: User does not own this moment
- `404 Not Found`: Moment not found
- `500 Internal Server Error`: Server error

### 9. Get Timeline with Pagination

**GET** `/timeline`

Retrieve user day summaries with cursor-based pagination for infinite scrolling timeline.

#### Query Parameters

- `cursor` (optional): Date cursor for pagination (ISO date-time format)
- `limit` (optional): Number of items per page (1-100, default: 20)

#### Request Headers

```
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
      "createdAt": "2024-01-16T02:00:00Z"
    }
  ],
  "nextCursor": "2024-01-15T00:00:00Z",
  "hasNextPage": true
}
```

#### Response Fields

- `data`: Array of day summary objects
- `nextCursor`: Date cursor for the next page (null if no more pages)
- `hasNextPage`: Boolean indicating if there are more pages

**Day Summary Object:**

- `id`: Unique identifier for the day summary
- `date`: The date this summary represents (start of day, ISO date-time)
- `text`: AI-generated summary text (null if no moments for this day)
- `tags`: Top 5 most popular tags from moments on this day
- `createdAt`: When the summary was created (ISO date-time)

#### Error Responses

- `400 Bad Request`: Invalid parameters
- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

### 10. Submit User Feedback

**POST** `/user/feedback`

Submit feedback from the user including title and description.

#### Request Headers

```
Content-Type: application/json
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

#### Response Fields

- `item`: User feedback object containing:
  - `id`: Unique identifier for the feedback
  - `title`: Title of the feedback
  - `text`: Detailed feedback text
  - `createdAt`: When the feedback was submitted (ISO date-time)

#### Error Responses

- `400 Bad Request`: Invalid request body (missing required fields, text too long, etc.)
- `401 Unauthorized`: Missing or invalid user ID
- `500 Internal Server Error`: Server error

## Data Models

### User

```json
{
  "id": "string",
  "userId": "string",
  "status": "newcomer" | "paywall_needed" | "premium"
}
```

### Moment

```json
{
  "id": "string",
  "text": "string",
  "submittedAt": "string (ISO date-time)",
  "happenedAt": "string (ISO date-time)",
  "tz": "string",
  "action": "string",
  "tags": "string[]",
  "praise": "string",
  "isFavorite": "boolean",
  "timeAgo": "integer | null",
  "archivedAt": "string (ISO date-time) | null"
}
```

**Required Fields:**

- `id`: Unique identifier for the moment
- `text`: The moment text content
- `submittedAt`: When the moment was submitted (ISO date-time)
- `happenedAt`: When the moment actually happened (calculated as submittedAt - timeAgo, ISO date-time)
- `tz`: Timezone of the user

**Optional Fields:**

- `action`: Normalized action from the moment text
- `tags`: Tags extracted from the moment during normalization (e.g., ["milestone", "writing", "streak"])
- `praise`: Generated praise message for the moment
- `isFavorite`: Whether the moment is marked as favorite
- `timeAgo`: Seconds passed from when the moment actually happened to when it was submitted (null if not specified)
- `archivedAt`: When the moment was archived (null if not archived)

### CreateMomentRequest

```json
{
  "text": "string (1-1000 characters)",
  "submittedAt": "string (ISO date-time, optional)",
  "tz": "string (optional)",
  "timeAgo": "integer (optional, nullable)"
}
```

**Fields:**

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
  "hasNextPage": "boolean"
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

**Required Fields:**

- `id`: Unique identifier for the feedback
- `title`: Title of the feedback
- `text`: Detailed feedback text
- `createdAt`: When the feedback was submitted (ISO date-time)

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
  "createdAt": "string (ISO date-time)"
}
```

**Required Fields:**

- `id`: Unique identifier for the day summary
- `date`: The date this summary represents (start of day, ISO date-time)
- `tags`: Top 5 most popular tags from moments on this day
- `createdAt`: When the summary was created (ISO date-time)

**Optional Fields:**

- `text`: AI-generated summary text (null if no moments for this day)

### PaginatedTimelineResponse

```json
{
  "data": "DaySummary[]",
  "nextCursor": "string (ISO date-time) | null",
  "hasNextPage": "boolean"
}
```

### ErrorResponse

```json
{
  "error": "string",
  "message": "string (optional)"
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

## Error Responses

### 400 Bad Request

```json
{
  "error": "Invalid cursor format",
  "message": "Cursor must be a valid ISO timestamp"
}
```

```json
{
  "error": "Daily limit reached",
  "message": "You can only submit 5 moments per day"
}
```

### 401 Unauthorized

```json
{
  "error": "Unauthorized",
  "message": "Missing or invalid user ID"
}
```

### 403 Forbidden

```json
{
  "error": "Forbidden",
  "message": "User does not own this moment"
}
```

### 404 Not Found

```json
{
  "error": "Not Found",
  "message": "Moment not found"
}
```

### 500 Internal Server Error

```json
{
  "error": "Internal Server Error",
  "message": "An unexpected error occurred"
}
```

## Client-Side Implementation Guidelines

### React Query Integration

The API is designed to work seamlessly with TanStack Query's `useInfiniteQuery`:

```typescript
const useMoments = () => {
  return useInfiniteQuery({
    queryKey: ["moments"],
    queryFn: ({ pageParam }) =>
      fetch(`/api/v1/moments?cursor=${pageParam}&limit=20`, {
        headers: { "x-user-id": userId },
      }).then((res) => res.json()),
    getNextPageParam: (lastPage) =>
      lastPage.hasNextPage ? lastPage.nextCursor : undefined,
    initialPageParam: undefined,
  });
};
```

### Authentication Headers

All requests must include the `x-user-id` header:

```typescript
const apiClient = {
  get: (url: string) =>
    fetch(`${baseUrl}${url}`, {
      headers: { "x-user-id": getCurrentUserId() },
    }),

  post: (url: string, data: any) =>
    fetch(`${baseUrl}${url}`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-user-id": getCurrentUserId(),
      },
      body: JSON.stringify(data),
    }),
};
```

### Error Handling

Implement proper error handling for all API responses:

```typescript
const handleApiError = (error: any) => {
  if (error.status === 400) {
    // Handle validation errors
    if (error.error === "Daily limit reached") {
      showDailyLimitMessage();
    }
  } else if (error.status === 401) {
    // Handle authentication errors
    redirectToLogin();
  } else if (error.status === 403) {
    // Handle permission errors
    showPermissionDeniedMessage();
  }
};
```

### State Management

Consider the following state management patterns:

1. **Optimistic Updates**: Update UI immediately for better UX
2. **Cache Invalidation**: Invalidate moments cache when creating/updating
3. **Background Refetching**: Keep data fresh with background updates
4. **Error Recovery**: Provide retry mechanisms for failed requests

## Testing Scenarios

### Test Cases

1. **Initial load**: No cursor, should return first page
2. **Forward pagination**: With cursor, should return next page
3. **Last page**: Should set `hasNextPage` to false
4. **Invalid cursor**: Should return 400 error
5. **Large limit**: Should return 400 if limit > 100
6. **Empty results**: Should return empty data array with `hasNextPage: false`
7. **Daily limit**: Should prevent more than 5 moments per day
8. **Ownership**: Should prevent users from modifying others' moments
9. **Archiving**: Should soft delete moments instead of hard delete

### Example Test Sequence

```
1. GET /api/v1/moments?limit=5
   → Returns first 5 moments, hasNextPage: true

2. GET /api/v1/moments?cursor=2024-01-15T10:30:00Z&limit=5
   → Returns next 5 moments, hasNextPage: true

3. GET /api/v1/moments?cursor=2024-01-10T08:15:00Z&limit=5
   → Returns next 5 moments, hasNextPage: false (last page)

4. POST /api/v1/moments (5th moment of the day)
   → Success

5. POST /api/v1/moments (6th moment of the day)
   → 400 Bad Request - Daily limit reached
```

## Business Rules

### Daily Limits

- Users can submit a maximum of **5 moments per day**
- Daily limit resets at midnight in the user's timezone
- Attempting to exceed the limit returns a 400 error

### User Status

- **newcomer**: New user with basic access
- **paywall_needed**: User needs to upgrade for premium features
- **premium**: Full access to all features

### Moment Lifecycle

1. **Created**: Moment is submitted and stored
2. **Updated**: Favorite status can be toggled
3. **Archived**: Moment is soft-deleted (not permanently removed)
4. **Retrieved**: Only non-archived moments are returned in queries

### Data Validation

- **Text length**: 1-1000 characters
- **Timestamp format**: ISO 8601 date-time strings
- **Timezone**: Standard timezone identifiers (e.g., "America/New_York")
- **Cursor format**: Valid ISO timestamp for pagination
