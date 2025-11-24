/**
 * User-Friendly Error Messages
 * Converts technical errors into user-friendly messages
 */

import {
  ApiError,
  NetworkError,
  TimeoutError,
  OfflineError,
  AuthError,
  ValidationError,
  NotFoundError,
  RateLimitError,
  ServerError,
  UserIdError,
} from "./apiErrors";

type ErrorMessageConfig = {
  title: string;
  message: string;
  action?: string;
  isRetryable: boolean;
};

/**
 * Get user-friendly error message from error object
 */
export const getUserFriendlyError = (error: unknown): ErrorMessageConfig => {
  // Handle offline
  if (error instanceof OfflineError) {
    return {
      title: "No Connection",
      message: "You're currently offline. Please check your internet connection and try again.",
      action: "Check Connection",
      isRetryable: false,
    };
  }

  // Handle network errors
  if (error instanceof NetworkError) {
    return {
      title: "Connection Failed",
      message: "We couldn't reach the server. Please check your connection and try again.",
      action: "Retry",
      isRetryable: true,
    };
  }

  // Handle timeout
  if (error instanceof TimeoutError) {
    return {
      title: "Request Timed Out",
      message: "The request took too long. Please try again.",
      action: "Try Again",
      isRetryable: true,
    };
  }

  // Handle authentication errors
  if (error instanceof AuthError) {
    return {
      title: "Authentication Required",
      message: "Please restart the app to continue.",
      action: "Restart App",
      isRetryable: false,
    };
  }

  // Handle validation errors
  if (error instanceof ValidationError) {
    const errorMessage = error.errors
      ? Object.values(error.errors).flat().join(", ")
      : error.message;

    return {
      title: "Invalid Input",
      message: errorMessage || "Please check your input and try again.",
      action: "Go Back",
      isRetryable: false,
    };
  }

  // Handle not found
  if (error instanceof NotFoundError) {
    return {
      title: "Not Found",
      message: "The item you're looking for doesn't exist or has been removed.",
      action: "Go Back",
      isRetryable: false,
    };
  }

  // Handle rate limiting
  if (error instanceof RateLimitError) {
    const retryMinutes = error.retryAfter
      ? Math.ceil(error.retryAfter / 60)
      : 1;

    return {
      title: "Too Many Requests",
      message: `You're doing that too often. Please wait ${retryMinutes} minute${retryMinutes > 1 ? "s" : ""} and try again.`,
      action: "Wait",
      isRetryable: false,
    };
  }

  // Handle server errors
  if (error instanceof ServerError) {
    return {
      title: "Server Error",
      message: "Something went wrong on our end. We're working on it. Please try again in a moment.",
      action: "Try Again",
      isRetryable: true,
    };
  }

  // Handle user ID errors (should rarely be seen by users)
  if (error instanceof UserIdError) {
    return {
      title: "Setup Error",
      message: "Please restart the app to continue.",
      action: "Restart App",
      isRetryable: false,
    };
  }

  // Handle generic API errors
  if (error instanceof ApiError) {
    return {
      title: "Something Went Wrong",
      message: error.message || "An unexpected error occurred. Please try again.",
      action: error.isRetryable ? "Try Again" : "Go Back",
      isRetryable: error.isRetryable,
    };
  }

  // Handle unknown errors
  if (error instanceof Error) {
    return {
      title: "Unexpected Error",
      message: error.message || "Something unexpected happened. Please try again.",
      action: "Try Again",
      isRetryable: true,
    };
  }

  // Fallback for non-Error objects
  return {
    title: "Something Went Wrong",
    message: "An unexpected error occurred. Please try again.",
    action: "Try Again",
    isRetryable: true,
  };
};

/**
 * Get just the title for compact error displays
 */
export const getErrorTitle = (error: unknown): string => {
  return getUserFriendlyError(error).title;
};

/**
 * Get just the message for compact error displays
 */
export const getErrorMessage = (error: unknown): string => {
  return getUserFriendlyError(error).message;
};

/**
 * Check if error is retryable
 */
export const isErrorRetryable = (error: unknown): boolean => {
  return getUserFriendlyError(error).isRetryable;
};
