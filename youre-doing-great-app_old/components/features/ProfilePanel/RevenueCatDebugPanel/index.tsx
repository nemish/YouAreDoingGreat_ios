import CommonText from "@/components/ui/CommonText";
import { useRevenueCatCustomerInfoQuery } from "@/hooks/useRevenueCatCustomerInfoQuery";
import * as Clipboard from "expo-clipboard";
import React, { useState } from "react";
import { Alert, TextInput, TouchableOpacity, View } from "react-native";

const RevenueCatDebugPanel = () => {
  const { data: customerInfo, isLoading } = useRevenueCatCustomerInfoQuery();
  const [copied, setCopied] = useState(false);

  // Only render in development or preview environments
  const env = process.env.EXPO_PUBLIC_ENV;
  if (env === "production") {
    return null;
  }

  const customerInfoJson = customerInfo
    ? JSON.stringify(customerInfo, null, 2)
    : "No customer info available";

  const handleCopy = async () => {
    try {
      await Clipboard.setStringAsync(customerInfoJson);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
      Alert.alert("Copied!", "RevenueCat customer info copied to clipboard");
    } catch (error) {
      Alert.alert("Error", "Failed to copy to clipboard");
    }
  };

  return (
    <View className="rounded-2xl bg-gray-800/50 p-4">
      {/* Header */}
      <View className="mb-3 flex-row items-center justify-between">
        <CommonText className="text-lg font-semibold text-white">
          Debug Info Panel
        </CommonText>
        <View className="rounded-full bg-yellow-500/20 px-3 py-1">
          <CommonText className="text-xs font-semibold text-yellow-400">
            {env?.toUpperCase()}
          </CommonText>
        </View>
      </View>

      {/* Loading State */}
      {isLoading && (
        <CommonText className="text-sm text-gray-400">
          Loading customer info...
        </CommonText>
      )}

      {/* Customer Info Display */}
      {!isLoading && (
        <>
          <TextInput
            value={customerInfoJson}
            multiline
            editable={false}
            scrollEnabled
            className="mb-3 max-h-60 rounded-lg bg-gray-900/70 p-3 font-mono text-xs text-green-400"
            textAlignVertical="top"
          />

          {/* Copy Button */}
          <TouchableOpacity
            onPress={handleCopy}
            className="rounded-lg bg-blue-600 py-3"
            activeOpacity={0.7}
          >
            <CommonText className="text-center font-semibold text-white">
              {copied ? "✓ Copied!" : "Copy to Clipboard"}
            </CommonText>
          </TouchableOpacity>
        </>
      )}
    </View>
  );
};

export default RevenueCatDebugPanel;
