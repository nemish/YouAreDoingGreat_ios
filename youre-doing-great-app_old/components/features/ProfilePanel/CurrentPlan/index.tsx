import CommonText from "@/components/ui/CommonText";
import FancyButton from "@/components/ui/FancyButton";
import LinkWithDescription from "@/components/ui/LinkWithDescription";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useIsPremium from "@/hooks/useIsPremium";
import { useRestorePurchases } from "@/hooks/useRestorePurchases";
import React, { useCallback } from "react";
import { Pressable, View } from "react-native";

const CurrentPlan = React.memo(() => {
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  const setMainPanelState = useMainPanelStore(
    (state) => state.setMainPanelState
  );
  const restorePurchasesMutation = useRestorePurchases();

  const handleUpgradeToPremium = useCallback(() => {
    setMainPanelState("paywall");
    setIsShown(true);
  }, []);

  const handleRestorePurchases = useCallback(() => {
    restorePurchasesMutation.mutate();
  }, [restorePurchasesMutation]);

  const isPremium = useIsPremium();

  return (
    <View className="p-4 flex gap-4">
      <CommonText className="text-xl font-bold text-white">
        Current Plan
      </CommonText>

      <View className="flex gap-2">
        <CommonText className="text-xl font-bold text-orange-300 capitalize">
          {isPremium ? "Premium" : "Free"}
        </CommonText>
        <CommonText className="text-orange-300/70">
          {isPremium
            ? "Enjoy 50 moments per day and advanced analytics"
            : "Limited to 3 moments per day"}
        </CommonText>
      </View>

      {!isPremium && (
        <View className="flex-row items-center justify-between mb-4 gap-4">
          <View className="flex-1">
            <CommonText className="text-white/60 text-sm">
              Unlock unlimited moments, advanced analytics, and premium features
            </CommonText>
          </View>

          <View className="w-36">
            <FancyButton
              text="Upgrade"
              onPress={handleUpgradeToPremium}
              size="base"
              kind="strawberry"
            />
          </View>
        </View>
      )}
      {/* Restore Purchases - Subtle Link */}
      {isPremium && (
        <View>
          <LinkWithDescription
            url="https://you-are-doing-great.com/support"
            text="How to cancel subscription?"
            description="Manage your subscription and cancel anytime"
          />
        </View>
      )}

      {/* Restore Purchases - Subtle Link */}
      {!isPremium && (
        <View>
          <Pressable
            onPress={handleRestorePurchases}
            disabled={restorePurchasesMutation.isPending}
            className="py-2"
          >
            <CommonText className="text-white text-center underline">
              {restorePurchasesMutation.isPending
                ? "Restoring..."
                : "Restore purchases"}
            </CommonText>
          </Pressable>
        </View>
      )}
    </View>
  );
});

CurrentPlan.displayName = "CurrentPlan";

export default CurrentPlan;
