import CommonText from "@/components/ui/CommonText";
import useUserProfile from "@/hooks/useUserProfile";
import { useUserStatsQuery } from "@/hooks/useUserStatsQuery";
import * as Clipboard from "expo-clipboard";
import * as Haptics from "expo-haptics";
import React, { useState } from "react";
import { Alert, TouchableOpacity, View } from "react-native";

const maskUserId = (userId: string | undefined): string => {
  if (!userId) return "Not available";
  if (userId.length <= 8) return userId;
  return `${userId.substring(0, 4)}...${userId.substring(userId.length - 4)}`;
};

const AccountInformation = React.memo(() => {
  const { user } = useUserProfile();
  const { data: stats } = useUserStatsQuery();
  const [copied, setCopied] = useState(false);

  const handleCopyUserId = async () => {
    if (!user?.userId) return;

    try {
      await Clipboard.setStringAsync(user.userId);
      await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (error) {
      console.error("Failed to copy user ID:", error);
      Alert.alert("Error", "Failed to copy user ID");
    }
  };

  return (
    <View className="rounded-2xl p-4">
      <CommonText className="mb-4 text-xl font-bold text-white">
        Account Information
      </CommonText>

      <View className="flex gap-2">
        <View className="flex-row justify-between items-center">
          <CommonText className="text-white/70">Your User ID:</CommonText>
          <TouchableOpacity
            onPress={handleCopyUserId}
            className="flex-row items-center gap-2"
          >
            <CommonText className="text-white font-semibold">
              {maskUserId(user?.userId)}
            </CommonText>
            {copied && (
              <CommonText className="text-white/50 text-xs">
                ✓ Copied
              </CommonText>
            )}
          </TouchableOpacity>
        </View>

        <View className="flex-row justify-between">
          <CommonText className="text-white/70">Total moments:</CommonText>
          <CommonText className="text-white font-semibold">
            {stats?.totalMoments ?? 0}
          </CommonText>
        </View>

        <View className="flex-row justify-between">
          <CommonText className="text-white/70">Moments today:</CommonText>
          <CommonText className="text-white font-semibold">
            {stats?.momentsToday ?? 0}
          </CommonText>
        </View>
      </View>
    </View>
  );
});

AccountInformation.displayName = "AccountInformation";

export default AccountInformation;
