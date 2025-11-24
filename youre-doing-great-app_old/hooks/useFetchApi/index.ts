import useUserIdStore from "@/hooks/stores/useUserIdStore";
import {
  NetworkError,
  OfflineError,
  TimeoutError,
  UserIdError,
  isRetryableError,
  parseApiError,
} from "@/utils/apiErrors";
import NetInfo from "@react-native-community/netinfo";
import * as Sentry from "@sentry/react-native";
import { useCallback } from "react";
import logger from "@/utils/logger";

const API_URL = `${process.env.EXPO_PUBLIC_API_URL}/api/v1`;

// Configuration
const DEFAULT_TIMEOUT = 10000; // 10 seconds
const MAX_RETRIES = 3;
const INITIAL_RETRY_DELAY = 1000; // 1 second

type FetchApiArgs = {
  path: string;
  method?: "GET" | "POST" | "PUT" | "DELETE";
  body?: any;
  headers?: Record<string, string>;
  timeout?: number;
  retry?: boolean;
  maxRetries?: number;
};

/**
 * Sleep utility for retry delays
 */
const sleep = (ms: number): Promise<void> => {
  return new Promise((resolve) => setTimeout(resolve, ms));
};

/**
 * Calculate exponential backoff delay
 * 1s, 2s, 4s, 8s, etc. with jitter
 */
const getRetryDelay = (attempt: number): number => {
  const baseDelay = INITIAL_RETRY_DELAY * Math.pow(2, attempt);
  // Add jitter (±25%) to prevent thundering herd
  const jitter = baseDelay * 0.25 * (Math.random() - 0.5);
  return baseDelay + jitter;
};

/**
 * Check if device is online
 */
const checkOnlineStatus = async (): Promise<boolean> => {
  try {
    const state = await NetInfo.fetch();
    return state.isConnected ?? false;
  } catch (error) {
    logger.warn("Failed to check network status:", error);
    // Assume online if check fails
    return true;
  }
};

/**
 * Fetch with timeout
 * Wraps fetch() with an AbortController to enforce timeout
 */
const fetchWithTimeout = async (
  url: string,
  options: RequestInit,
  timeout: number
): Promise<Response> => {
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...options,
      signal: controller.signal,
    });
    clearTimeout(timeoutId);
    return response;
  } catch (error: any) {
    clearTimeout(timeoutId);

    // Handle abort (timeout)
    if (error.name === "AbortError") {
      throw new TimeoutError();
    }

    // Handle network errors (no connection, DNS failure, etc.)
    if (
      error.message?.includes("Network request failed") ||
      error.message?.includes("Failed to fetch")
    ) {
      throw new NetworkError();
    }

    // Re-throw other errors
    throw error;
  }
};

/**
 * Main fetch API hook with comprehensive error handling
 */
const useFetchApi = () => {
  const userId = useUserIdStore((state) => state.userId);

  const fetchApi = useCallback(
    async ({
      path,
      method = "GET",
      body,
      headers = {},
      timeout = DEFAULT_TIMEOUT,
      retry = true,
      maxRetries = MAX_RETRIES,
    }: FetchApiArgs): Promise<Response> => {
      // Validate userId
      if (!userId) {
        const error = new UserIdError();
        Sentry.captureException(error, {
          tags: { errorType: "user_id_missing" },
          extra: { path, method },
        });
        throw error;
      }

      // Check if offline before attempting request
      const isOnline = await checkOnlineStatus();
      if (!isOnline) {
        const error = new OfflineError();
        // Don't report to Sentry (user offline is not an app error)
        throw error;
      }

      // Retry logic
      const attemptRequest = async (attempt: number): Promise<Response> => {
        try {
          // Prepare request
          const url = `${API_URL}${path}`;
          const options: RequestInit = {
            method,
            headers: {
              "Content-Type": "application/json",
              "x-user-id": userId,
              ...headers,
            },
          };

          if (body) {
            options.body = JSON.stringify(body);
          }

          // Make request with timeout
          const response = await fetchWithTimeout(url, options, timeout);

          // Handle HTTP errors
          if (!response.ok) {
            await parseApiError(response);
          }

          // Success
          return response;
        } catch (error: any) {
          // Determine if we should retry
          const shouldRetry =
            retry && attempt < maxRetries && isRetryableError(error);

          if (shouldRetry) {
            const delay = getRetryDelay(attempt);
            logger.debug(
              `Request failed (attempt ${
                attempt + 1
              }/${maxRetries}). Retrying in ${Math.round(delay)}ms...`,
              error.message
            );

            // Add breadcrumb for retry
            Sentry.addBreadcrumb({
              category: "api.retry",
              message: `Retrying ${method} ${path}`,
              level: "info",
              data: {
                attempt: attempt + 1,
                maxRetries,
                delay,
                error: error.message,
              },
            });

            await sleep(delay);
            return attemptRequest(attempt + 1);
          }

          // No more retries or not retryable - report to Sentry and throw
          if (attempt > 0) {
            Sentry.captureException(error, {
              tags: {
                errorType: error.name || "ApiError",
                retried: "true",
                attempts: String(attempt + 1),
              },
              extra: {
                path,
                method,
                userId,
                statusCode: error.statusCode,
              },
            });
          }

          throw error;
        }
      };

      // Start request with attempt 0
      return attemptRequest(0);
    },
    [userId]
  );

  return fetchApi;
};

export default useFetchApi;
