# Network Error Handling Guide

This guide documents the comprehensive network error handling system implemented for the "You Are Doing Great" app.

## Overview

The app now handles network requests with:
- ✅ **Timeout Protection** - Requests don't hang indefinitely
- ✅ **Automatic Retries** - Transient failures are retried automatically
- ✅ **Offline Detection** - Checks connectivity before making requests
- ✅ **Typed Errors** - 11 different error types for precise error handling
- ✅ **Smart Retry Logic** - Only retries network/server errors, not auth/validation
- ✅ **Exponential Backoff** - Prevents server overload with increasing delays
- ✅ **Sentry Integration** - Failed requests are tracked and reported

## Architecture

### Core Files

1. **`utils/apiErrors.ts`** - Typed error class definitions
2. **`hooks/useFetchApi/index.ts`** - Enhanced fetch hook with error handling

### Error Class Hierarchy

```
ApiError (base class)
├── NetworkError (retryable)
├── TimeoutError (retryable)
├── OfflineError (not retryable)
├── AuthError (not retryable)
├── ValidationError (not retryable)
├── NotFoundError (not retryable)
├── RateLimitError (retryable with delay)
├── ServerError (retryable)
└── UserIdError (not retryable)
```

## Error Types

### 1. NetworkError
**When**: DNS failure, connection refused, network unreachable
**Retryable**: Yes (up to 3 attempts)
**User Message**: "Network request failed. Please check your connection."

### 2. TimeoutError
**When**: Request takes longer than timeout (default 10s)
**Retryable**: Yes (up to 3 attempts)
**User Message**: "Request timed out. Please try again."
**HTTP Status**: 408

### 3. OfflineError
**When**: Device has no internet connection (detected via NetInfo)
**Retryable**: No (requires user action)
**User Message**: "No internet connection. Please check your network settings."

### 4. AuthError
**When**: HTTP 401 (Unauthorized) or 403 (Forbidden)
**Retryable**: No (requires authentication)
**User Message**: "Authentication failed."

### 5. ValidationError
**When**: HTTP 400 (Bad Request) or 422 (Unprocessable Entity)
**Retryable**: No (requires fixing input)
**User Message**: "Validation failed."
**Extra Data**: `errors` object with field-level validation errors

### 6. NotFoundError
**When**: HTTP 404 (Not Found)
**Retryable**: No
**User Message**: "Resource not found."

### 7. RateLimitError
**When**: HTTP 429 (Too Many Requests)
**Retryable**: Yes (respects `Retry-After` header)
**User Message**: "Too many requests. Please try again later."
**Extra Data**: `retryAfter` (seconds)

### 8. ServerError
**When**: HTTP 500, 502, 503, 504
**Retryable**: Yes (up to 3 attempts)
**User Message**: "Server error. Please try again."

### 9. UserIdError
**When**: userId is missing or empty
**Retryable**: No (app initialization error)
**User Message**: "User ID is required but not set."

## Usage

### Basic Usage

```typescript
const fetchApi = useFetchApi();

try {
  const response = await fetchApi({
    path: "/moments",
    method: "GET",
  });
  const data = await response.json();
} catch (error) {
  if (error instanceof ValidationError) {
    // Handle validation errors
    console.log("Validation errors:", error.errors);
  } else if (error instanceof OfflineError) {
    // Show offline message
    Alert.alert("No Internet", error.message);
  }
}
```

### Advanced Configuration

```typescript
const response = await fetchApi({
  path: "/moments",
  method: "POST",
  body: { text: "Great moment!" },
  headers: { "X-Custom-Header": "value" },
  timeout: 5000,        // 5 second timeout (default: 10s)
  retry: false,         // Disable retry (default: true)
  maxRetries: 5,        // Custom retry count (default: 3)
});
```

### Error Type Checking

```typescript
import { isApiError, isRetryableError } from "@/utils/apiErrors";

try {
  // ... make request
} catch (error) {
  if (isApiError(error)) {
    console.log("API Error:", error.statusCode);

    if (isRetryableError(error)) {
      console.log("This error is retryable");
    }
  }
}
```

## Retry Behavior

### Exponential Backoff

The system uses exponential backoff with jitter to prevent thundering herd:

| Attempt | Base Delay | With Jitter (±25%) | Total Time |
|---------|------------|-------------------|------------|
| 1       | 1s         | 0.75s - 1.25s     | ~1s        |
| 2       | 2s         | 1.5s - 2.5s       | ~3s        |
| 3       | 4s         | 3s - 5s           | ~7s        |

**Jitter** prevents multiple clients from retrying simultaneously, reducing server load.

### What Gets Retried

**Retryable Errors** (automatic retry):
- `NetworkError` - Network failures
- `TimeoutError` - Request timeouts
- `ServerError` - 500, 502, 503, 504
- `RateLimitError` - 429 (with delay)

**Not Retried** (fail immediately):
- `OfflineError` - User offline
- `AuthError` - 401, 403
- `ValidationError` - 400, 422
- `NotFoundError` - 404
- `UserIdError` - Missing userId

### Disabling Retry

For non-idempotent operations or when immediate failure is preferred:

```typescript
await fetchApi({
  path: "/payment",
  method: "POST",
  retry: false, // Don't retry failed payments
});
```

## Timeout Configuration

### Default Timeout
All requests timeout after **10 seconds** by default.

### Custom Timeout
```typescript
await fetchApi({
  path: "/large-upload",
  timeout: 30000, // 30 second timeout
});
```

### Timeout Behavior
1. AbortController signals abort after timeout
2. Fetch throws AbortError
3. Converted to `TimeoutError`
4. Retried automatically (if retry enabled)

## Offline Detection

### How It Works
1. Before every request, NetInfo checks device connectivity
2. If offline, throws `OfflineError` immediately (no network request made)
3. Saves battery and reduces unnecessary requests

### NetInfo States
- **Connected**: Has network connection (WiFi, cellular, etc.)
- **Disconnected**: No network connection
- **Unknown**: Can't determine (assumes online)

## Sentry Integration

### What Gets Reported

**Reported to Sentry**:
- Failed requests after all retries exhausted
- UserIdError (app initialization problem)
- Unexpected errors

**Not Reported to Sentry**:
- OfflineError (user offline, not app error)
- Successful requests
- Errors that will be retried

### Sentry Context

Each error includes:
```javascript
{
  tags: {
    errorType: "NetworkError",
    retried: "true",
    attempts: "3"
  },
  extra: {
    path: "/api/v1/moments",
    method: "POST",
    userId: "abc-123",
    statusCode: 500
  }
}
```

### Retry Breadcrumbs

When retrying, breadcrumbs are added to track retry attempts:
```javascript
{
  category: "api.retry",
  message: "Retrying POST /moments",
  level: "info",
  data: {
    attempt: 2,
    maxRetries: 3,
    delay: 2000,
    error: "Request timed out"
  }
}
```

## Migration Guide

### Old Code
```typescript
const fetchApi = useFetchApi();
const response = await fetchApi({
  path: "/moments",
  method: "GET",
});
```

### New Code (No Changes Required!)
The new implementation is **backward compatible**. All existing code continues to work with enhanced error handling automatically.

### Optional: Leverage New Features
```typescript
import { ValidationError, OfflineError } from "@/utils/apiErrors";

try {
  const response = await fetchApi({ path: "/moments" });
} catch (error) {
  if (error instanceof ValidationError) {
    // Show field-specific errors
    Object.entries(error.errors || {}).forEach(([field, messages]) => {
      console.log(`${field}: ${messages.join(", ")}`);
    });
  } else if (error instanceof OfflineError) {
    // Show offline UI
    showOfflineMessage();
  }
}
```

## Configuration

### Constants (in `useFetchApi/index.ts`)

```typescript
const DEFAULT_TIMEOUT = 10000;      // 10 seconds
const MAX_RETRIES = 3;              // Maximum retry attempts
const INITIAL_RETRY_DELAY = 1000;   // 1 second base delay
```

To change defaults, edit these constants in the file.

## Testing

### Testing Timeout
```typescript
// This will timeout after 1 second
await fetchApi({
  path: "/slow-endpoint",
  timeout: 1000,
});
```

### Testing Retry
```typescript
// Force retry by calling an endpoint that returns 500
await fetchApi({
  path: "/endpoint-that-returns-500",
  maxRetries: 5, // Try 5 times
});
```

### Testing Offline
```typescript
// Turn off WiFi/cellular, then:
await fetchApi({ path: "/moments" });
// Throws OfflineError immediately
```

## Best Practices

### 1. Don't Retry Mutations Without Idempotency
```typescript
// ❌ Bad: Could create duplicate records
await fetchApi({
  path: "/payments",
  method: "POST",
  // Retries enabled by default!
});

// ✅ Good: Disable retry for non-idempotent operations
await fetchApi({
  path: "/payments",
  method: "POST",
  retry: false,
});
```

### 2. Handle Specific Errors in UI
```typescript
// ✅ Good: Show specific error messages
catch (error) {
  if (error instanceof OfflineError) {
    showBanner("You're offline");
  } else if (error instanceof ValidationError) {
    showFormErrors(error.errors);
  } else {
    showGenericError();
  }
}
```

### 3. Use Appropriate Timeouts
```typescript
// ✅ Good: Short timeout for fast endpoints
await fetchApi({ path: "/health", timeout: 3000 });

// ✅ Good: Long timeout for file uploads
await fetchApi({ path: "/upload", timeout: 60000 });
```

### 4. Don't Swallow Errors
```typescript
// ❌ Bad: Silent failure
catch (error) {
  console.log(error);
}

// ✅ Good: Show user feedback
catch (error) {
  Alert.alert("Error", error.message);
  Sentry.captureException(error); // If not auto-reported
}
```

## Troubleshooting

### Requests Timing Out Too Fast
**Issue**: Legitimate slow requests are timing out

**Solution**: Increase timeout for specific endpoints
```typescript
await fetchApi({ path: "/export", timeout: 30000 });
```

### Too Many Retries
**Issue**: Failed requests retry too many times

**Solution**: Reduce maxRetries or disable retry
```typescript
await fetchApi({ path: "/endpoint", maxRetries: 1 });
```

### Offline Detection Not Working
**Issue**: OfflineError not thrown when offline

**Check**:
1. NetInfo package installed: `npm list @react-native-community/netinfo`
2. Device actually offline (check other apps)
3. NetInfo permissions granted (iOS/Android)

### Validation Errors Not Showing
**Issue**: ValidationError thrown but errors object is undefined

**Check**: Server must return validation errors in this format:
```json
{
  "message": "Validation failed",
  "errors": {
    "email": ["Email is required"],
    "password": ["Password must be at least 8 characters"]
  }
}
```

## Future Enhancements

Potential improvements:
- [ ] Request deduplication (cancel duplicate in-flight requests)
- [ ] Request queuing when offline
- [ ] Circuit breaker pattern (stop trying after repeated failures)
- [ ] Per-endpoint retry configuration
- [ ] Request caching with cache headers
- [ ] Upload/download progress callbacks

---

**Last Updated**: 2025-10-25
