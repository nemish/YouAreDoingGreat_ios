import HidePanelControl from "@/components/features/HomeScreen/HidePanelControl";
import useHidePanelGesture from "@/components/features/HomeScreen/hooks/useHidePanelGesture";
import InitMomentPanel from "@/components/features/HomeScreen/InitMomentPanel";
import Paywall from "@/components/features/HomeScreen/Paywall";
import SubmitMomentPanel from "@/components/features/HomeScreen/SubmitMomentPanel";
import SubmittingProgressPanel from "@/components/features/HomeScreen/SubmittingProgressPanel";
import Modals from "@/components/features/Modals";
// import { BackgroundFX } from "@/components/ui/BackgroundFX";
import { ErrorBoundary } from "@/components/ErrorBoundary";
import BackgroundFXLottie from "@/components/ui/BackgroundFXLottie";
import OfflineBanner from "@/components/ui/OfflineBanner";
import useHighlightedItemStore from "@/hooks/stores/useHighlightedItem";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useUserProfile from "@/hooks/useUserProfile";
import { Stack } from "expo-router";
import { AnimatePresence, MotiView } from "moti";
import React from "react";
import { StyleSheet, View } from "react-native";
import { GestureDetector } from "react-native-gesture-handler";
import Animated, { useAnimatedStyle } from "react-native-reanimated";
import logger from "@/utils/logger";

export default function TabsLayout() {
  const mainPanelState = useMainPanelStore((state) => state.mainPanelState);
  const setMainPanelState = useMainPanelStore(
    (state) => state.setMainPanelState
  );
  const setHighlightedItem = useHighlightedItemStore(
    (state) => state.setHighlightedItem
  );
  useMainPanelStore.subscribe((state) => {
    if (state.isInitMomentPanelShown) {
      setHighlightedItem(null);
    }
  });

  const onPress = () => {
    setMainPanelState("submitForm");
  };

  const { swipeGesture, translateY, isHidden, isPanning } =
    useHidePanelGesture();

  const { user, customerInfo } = useUserProfile();
  logger.debug("user customerInfo", { user, customerInfo });

  const animatedStyle = useAnimatedStyle(() => {
    return {
      transform: [{ translateY: translateY.value }],
    };
  });

  return (
    <ErrorBoundary>
      <View className="flex-1 flex relative">
        <OfflineBanner />
        <Stack
          screenOptions={{
            animation: "fade",
            animationDuration: 300,
          }}
        >
          <Stack.Screen name="index" options={{ headerShown: false }} />
          <Stack.Screen name="timeline" options={{ headerShown: false }} />
          <Stack.Screen name="profile" options={{ headerShown: false }} />
        </Stack>
        <Modals />
        <Animated.View
          className="absolute top-16 left-0 right-0 bottom-0 z-10"
          style={[animatedStyle, styles.shadowProp]}
        >
          <View className="w-full h-full flex z-9 rounded-t-3xl absolute top-0 left-0 overflow-hidden">
            <BackgroundFXLottie />
            {/* <BackgroundFX isPanning={isPanning} /> */}
            {/* <AnimatedBlobsBackground isPanning={isPanning} /> */}
          </View>
          <GestureDetector gesture={swipeGesture}>
            <View className="w-full h-full flex z-9 rounded-t-3xl absolute top-0 left-0 z-10">
              <AnimatePresence exitBeforeEnter>
                {mainPanelState === "init" && (
                  <MotiView
                    key="init-moment-panel"
                    from={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{
                      delay: 500,
                      type: "timing",
                      duration: 500,
                    }}
                    exitTransition={{ delay: 0, duration: 300 }}
                    className="flex-1"
                  >
                    <InitMomentPanel onPress={onPress} />
                  </MotiView>
                )}
                {mainPanelState === "paywall" && (
                  <MotiView
                    key="paywall-panel"
                    from={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{
                      type: "timing",
                      duration: 500,
                    }}
                    exitTransition={{ delay: 0, duration: 300 }}
                    className="flex-1"
                  >
                    <Paywall />
                  </MotiView>
                )}
                {mainPanelState === "submitForm" && (
                  <MotiView
                    key="submit-moment-panel"
                    from={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{
                      type: "timing",
                      duration: 500,
                    }}
                    className="flex-1 flex items-center justify-center"
                  >
                    <SubmitMomentPanel />
                  </MotiView>
                )}
                {mainPanelState === "submittingProgress" && (
                  <MotiView
                    key="submitting-progress-panel"
                    from={{ opacity: 0 }}
                    animate={{ opacity: 1 }}
                    exit={{ opacity: 0 }}
                    transition={{
                      type: "timing",
                      duration: 500,
                    }}
                    className="flex-1 flex items-center justify-center"
                  >
                    <SubmittingProgressPanel />
                  </MotiView>
                )}
              </AnimatePresence>
              <HidePanelControl isHidden={isHidden} isPanning={isPanning} />
            </View>
          </GestureDetector>
        </Animated.View>
      </View>
    </ErrorBoundary>
  );
}

const styles = StyleSheet.create({
  shadowProp: {
    shadowOffset: { width: 0, height: -2 },
    shadowRadius: 16,
    shadowOpacity: 0.3,
    elevation: 2,
    shadowColor: "#fff",
  },
});
