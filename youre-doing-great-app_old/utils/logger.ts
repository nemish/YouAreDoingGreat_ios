/**
 * Application Logger
 * Conditional logging that respects environment and integrates with Sentry
 */

import * as Sentry from "@sentry/react-native";

type LogLevel = "debug" | "info" | "warn" | "error";

/**
 * Check if we're in development mode
 */
const isDev = __DEV__;

/**
 * Check if we're in production mode
 */
const isProd = process.env.EXPO_PUBLIC_ENV === "production";

/**
 * Logger class with environment-aware logging
 */
class Logger {
  /**
   * Debug logs (only in development)
   * Use for verbose debugging information
   */
  debug(...args: any[]): void {
    if (isDev) {
      console.log("[DEBUG]", ...args);
    }
  }

  /**
   * Info logs (only in development)
   * Use for general information
   */
  info(...args: any[]): void {
    if (isDev) {
      console.log("[INFO]", ...args);
    }
  }

  /**
   * Warning logs (always logged, sent to Sentry in production)
   * Use for unexpected but recoverable situations
   */
  warn(...args: any[]): void {
    console.warn("[WARN]", ...args);

    if (isProd) {
      // Send warnings to Sentry in production
      const message = args.map((arg) => String(arg)).join(" ");
      Sentry.captureMessage(message, "warning");
    }
  }

  /**
   * Error logs (always logged, always sent to Sentry)
   * Use for errors that need attention
   */
  error(...args: any[]): void {
    console.error("[ERROR]", ...args);

    // Always send errors to Sentry (unless in dev and disabled)
    if (!isDev || isProd) {
      // If first arg is an Error object, use it directly
      if (args[0] instanceof Error) {
        Sentry.captureException(args[0], {
          extra: {
            additionalData: args.slice(1),
          },
        });
      } else {
        // Otherwise create a message
        const message = args.map((arg) => String(arg)).join(" ");
        Sentry.captureMessage(message, "error");
      }
    }
  }

  /**
   * Log with a specific tag/category
   * Useful for filtering logs by feature
   */
  tagged(tag: string) {
    return {
      debug: (...args: any[]) => this.debug(`[${tag}]`, ...args),
      info: (...args: any[]) => this.info(`[${tag}]`, ...args),
      warn: (...args: any[]) => this.warn(`[${tag}]`, ...args),
      error: (...args: any[]) => this.error(`[${tag}]`, ...args),
    };
  }

  /**
   * Log API requests/responses (only in development)
   */
  api(method: string, path: string, data?: any): void {
    if (isDev) {
      console.log(`[API] ${method} ${path}`, data || "");
    }
  }

  /**
   * Log navigation events (only in development)
   */
  navigation(screen: string, params?: any): void {
    if (isDev) {
      console.log(`[NAV] → ${screen}`, params || "");
    }
  }

  /**
   * Log performance metrics (only in development)
   */
  perf(label: string, duration: number): void {
    if (isDev) {
      console.log(`[PERF] ${label}: ${duration.toFixed(2)}ms`);
    }
  }
}

/**
 * Global logger instance
 * Import and use throughout the app
 */
export const logger = new Logger();

/**
 * Create a tagged logger for a specific module/feature
 * Example: const log = createLogger('UserAuth');
 */
export const createLogger = (tag: string) => logger.tagged(tag);

/**
 * Legacy support - direct export of methods
 * This allows gradual migration from console.log
 */
export const log = {
  debug: logger.debug.bind(logger),
  info: logger.info.bind(logger),
  warn: logger.warn.bind(logger),
  error: logger.error.bind(logger),
  api: logger.api.bind(logger),
  navigation: logger.navigation.bind(logger),
  perf: logger.perf.bind(logger),
};

export default logger;
