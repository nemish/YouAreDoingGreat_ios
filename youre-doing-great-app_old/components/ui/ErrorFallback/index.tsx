import { View, TouchableOpacity } from "react-native";
import CommonText from "@/components/ui/CommonText";
import { getUserFriendlyError } from "@/utils/errorMessages";

type ErrorFallbackProps = {
  error: unknown;
  onRetry?: () => void;
  compact?: boolean;
};

/**
 * ErrorFallback Component
 * Displays user-friendly error messages with optional retry button
 */
export const ErrorFallback = ({ error, onRetry, compact = false }: ErrorFallbackProps) => {
  const errorInfo = getUserFriendlyError(error);

  if (compact) {
    // Compact version for inline errors
    return (
      <View className="py-4 px-6">
        <CommonText className="text-red-400 text-sm text-center mb-2">
          {errorInfo.title}
        </CommonText>
        <CommonText className="text-gray-400 text-xs text-center mb-4">
          {errorInfo.message}
        </CommonText>
        {onRetry && errorInfo.isRetryable && (
          <TouchableOpacity
            onPress={onRetry}
            className="bg-blue-600 px-6 py-2 rounded-full self-center active:bg-blue-700"
          >
            <CommonText className="text-white text-sm font-semibold">
              {errorInfo.action || "Try Again"}
            </CommonText>
          </TouchableOpacity>
        )}
      </View>
    );
  }

  // Full-screen version for major errors
  return (
    <View className="flex-1 bg-neutral-900 items-center justify-center px-8">
      <View className="items-center gap-6 max-w-sm">
        {/* Error Icon */}
        <View className="w-20 h-20 rounded-full bg-red-500/20 items-center justify-center">
          <CommonText className="text-red-500 text-4xl">⚠️</CommonText>
        </View>

        {/* Error Title */}
        <CommonText className="text-white text-xl font-semibold text-center">
          {errorInfo.title}
        </CommonText>

        {/* Error Message */}
        <CommonText className="text-gray-400 text-center text-sm leading-6">
          {errorInfo.message}
        </CommonText>

        {/* Retry Button */}
        {onRetry && errorInfo.isRetryable && (
          <TouchableOpacity
            onPress={onRetry}
            className="bg-blue-600 px-8 py-3 rounded-full active:bg-blue-700"
          >
            <CommonText className="text-white font-semibold">
              {errorInfo.action || "Try Again"}
            </CommonText>
          </TouchableOpacity>
        )}

        {/* Action Button for Non-Retryable Errors */}
        {!errorInfo.isRetryable && errorInfo.action && (
          <CommonText className="text-gray-500 text-sm">
            {errorInfo.action}
          </CommonText>
        )}
      </View>
    </View>
  );
};

export default ErrorFallback;
