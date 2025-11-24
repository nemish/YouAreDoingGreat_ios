/**
 * API Error Classes
 * Typed errors for different API failure scenarios
 */

/**
 * Base API Error class
 * All API errors extend from this
 */
export class ApiError extends Error {
  statusCode?: number;
  isRetryable: boolean;

  constructor(message: string, statusCode?: number, isRetryable = false) {
    super(message);
    this.name = "ApiError";
    this.statusCode = statusCode;
    this.isRetryable = isRetryable;

    // Maintains proper stack trace for where our error was thrown (only available on V8)
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}

/**
 * Network error (no internet, DNS failure, etc.)
 * RETRYABLE
 */
export class NetworkError extends ApiError {
  constructor(message = "Network request failed. Please check your connection.") {
    super(message, undefined, true);
    this.name = "NetworkError";
  }
}

/**
 * Request timeout error
 * RETRYABLE
 */
export class TimeoutError extends ApiError {
  constructor(message = "Request timed out. Please try again.") {
    super(message, 408, true);
    this.name = "TimeoutError";
  }
}

/**
 * No internet connection
 * NOT RETRYABLE (requires user action)
 */
export class OfflineError extends ApiError {
  constructor(message = "No internet connection. Please check your network settings.") {
    super(message, undefined, false);
    this.name = "OfflineError";
  }
}

/**
 * Authentication/Authorization error (401, 403)
 * NOT RETRYABLE
 */
export class AuthError extends ApiError {
  constructor(message = "Authentication failed.", statusCode = 401) {
    super(message, statusCode, false);
    this.name = "AuthError";
  }
}

/**
 * Validation error (400, 422)
 * NOT RETRYABLE (requires user to fix input)
 */
export class ValidationError extends ApiError {
  errors?: Record<string, string[]>;

  constructor(message = "Validation failed.", errors?: Record<string, string[]>, statusCode = 400) {
    super(message, statusCode, false);
    this.name = "ValidationError";
    this.errors = errors;
  }
}

/**
 * Resource not found (404)
 * NOT RETRYABLE
 */
export class NotFoundError extends ApiError {
  constructor(message = "Resource not found.", statusCode = 404) {
    super(message, statusCode, false);
    this.name = "NotFoundError";
  }
}

/**
 * Rate limiting error (429)
 * RETRYABLE (after delay)
 */
export class RateLimitError extends ApiError {
  retryAfter?: number; // seconds

  constructor(message = "Too many requests. Please try again later.", retryAfter?: number) {
    super(message, 429, true);
    this.name = "RateLimitError";
    this.retryAfter = retryAfter;
  }
}

/**
 * Server error (500, 502, 503, 504)
 * RETRYABLE
 */
export class ServerError extends ApiError {
  constructor(message = "Server error. Please try again.", statusCode = 500) {
    super(message, statusCode, true);
    this.name = "ServerError";
  }
}

/**
 * User ID missing or invalid
 * NOT RETRYABLE (app error)
 */
export class UserIdError extends ApiError {
  constructor(message = "User ID is required but not set.") {
    super(message, undefined, false);
    this.name = "UserIdError";
  }
}

/**
 * Parse HTTP response and throw appropriate error
 */
export const parseApiError = async (response: Response): Promise<never> => {
  const status = response.status;
  let errorMessage = `Request failed with status ${status}`;
  let errorData: any = null;

  // Try to parse error response body
  try {
    const contentType = response.headers.get("content-type");
    if (contentType?.includes("application/json")) {
      errorData = await response.json();
      errorMessage = errorData.message || errorData.error || errorMessage;
    } else {
      const text = await response.text();
      if (text) {
        errorMessage = text;
      }
    }
  } catch {
    // Failed to parse error body, use default message
  }

  // Throw specific error based on status code
  switch (status) {
    case 400:
    case 422:
      throw new ValidationError(errorMessage, errorData?.errors, status);

    case 401:
    case 403:
      throw new AuthError(errorMessage, status);

    case 404:
      throw new NotFoundError(errorMessage, status);

    case 408:
      throw new TimeoutError(errorMessage);

    case 429:
      const retryAfter = parseInt(response.headers.get("retry-after") || "60");
      throw new RateLimitError(errorMessage, retryAfter);

    case 500:
    case 502:
    case 503:
    case 504:
      throw new ServerError(errorMessage, status);

    default:
      // Generic API error for other status codes
      throw new ApiError(errorMessage, status, status >= 500);
  }
};

/**
 * Type guard to check if error is an API error
 */
export const isApiError = (error: unknown): error is ApiError => {
  return error instanceof ApiError;
};

/**
 * Type guard to check if error is retryable
 */
export const isRetryableError = (error: unknown): boolean => {
  return isApiError(error) && error.isRetryable;
};
