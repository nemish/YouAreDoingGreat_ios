import React from "react";
import { View, TouchableOpacity } from "react-native";
import CommonText from "@/components/ui/CommonText";
import * as Sentry from "@sentry/react-native";
import logger from "@/utils/logger";

type ErrorBoundaryProps = {
  children: React.ReactNode;
  fallback?: (error: Error, retry: () => void) => React.ReactNode;
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void;
};

type ErrorBoundaryState = {
  hasError: boolean;
  error: Error | null;
};

export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props);
    this.state = {
      hasError: false,
      error: null,
    };
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return {
      hasError: true,
      error,
    };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log error details (only in development)
    logger.error("ErrorBoundary caught error:", error, errorInfo);

    // Call custom error handler if provided
    this.props.onError?.(error, errorInfo);

    // Send to Sentry with component stack
    Sentry.captureException(error, {
      contexts: {
        react: {
          componentStack: errorInfo.componentStack,
        },
      },
    });
  }

  handleReset = () => {
    this.setState({
      hasError: false,
      error: null,
    });
  };

  render() {
    if (this.state.hasError && this.state.error) {
      // Use custom fallback if provided
      if (this.props.fallback) {
        return this.props.fallback(this.state.error, this.handleReset);
      }

      // Default error UI
      return (
        <View className="flex-1 bg-neutral-900 items-center justify-center px-8">
          <View className="items-center gap-6">
            {/* Error Icon */}
            <View className="w-20 h-20 rounded-full bg-red-500/20 items-center justify-center">
              <CommonText className="text-red-500 text-4xl">⚠️</CommonText>
            </View>

            {/* Error Title */}
            <CommonText className="text-white text-xl font-semibold text-center">
              Something went wrong
            </CommonText>

            {/* Error Message */}
            <CommonText className="text-gray-400 text-center text-sm leading-6">
              We encountered an unexpected error. This has been reported and
              we'll look into it.
            </CommonText>

            {/* Error Details (only in dev) */}
            {__DEV__ && (
              <View className="bg-neutral-800 rounded-lg p-4 w-full max-h-40">
                <CommonText className="text-red-400 text-xs">
                  {this.state.error.message}
                </CommonText>
                {this.state.error.stack && (
                  <CommonText className="text-gray-500 text-xs mt-2" numberOfLines={5}>
                    {this.state.error.stack}
                  </CommonText>
                )}
              </View>
            )}

            {/* Retry Button */}
            <TouchableOpacity
              onPress={this.handleReset}
              className="bg-blue-600 px-8 py-3 rounded-full active:bg-blue-700"
            >
              <CommonText className="text-white font-semibold">
                Try Again
              </CommonText>
            </TouchableOpacity>
          </View>
        </View>
      );
    }

    return this.props.children;
  }
}
