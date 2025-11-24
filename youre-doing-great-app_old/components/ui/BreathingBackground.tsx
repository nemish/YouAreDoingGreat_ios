import { LinearGradient } from "expo-linear-gradient";
import React from "react";
import { Dimensions, StyleSheet } from "react-native";
import Animated, {
  Easing,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";

const { width, height } = Dimensions.get("window");

const AnimatedLinearGradient = Animated.createAnimatedComponent(LinearGradient);

export const BreathingBackground = () => {
  const opacity = useSharedValue(1);
  const scale = useSharedValue(1);
  const colorProgress = useSharedValue(0);
  const rotation = useSharedValue(0);

  // Enhanced breathing effect with multiple animations
  React.useEffect(() => {
    // Opacity animation - more dramatic change
    opacity.value = withRepeat(
      withTiming(0.6, {
        duration: 3000,
        easing: Easing.inOut(Easing.ease),
      }),
      -1,
      true
    );

    // Scale animation - more dramatic scaling
    scale.value = withRepeat(
      withTiming(1.3, {
        duration: 4000,
        easing: Easing.inOut(Easing.cubic),
      }),
      -1,
      true
    );

    // Color transition animation - faster to be more noticeable
    colorProgress.value = withRepeat(
      withTiming(1, {
        duration: 5000,
        easing: Easing.inOut(Easing.sin),
      }),
      -1,
      true
    );

    // Add rotation for more visual interest
    rotation.value = withRepeat(
      withTiming(0.05, {
        duration: 6000,
        easing: Easing.inOut(Easing.quad),
      }),
      -1,
      true
    );
  }, []);

  const animatedStyle = useAnimatedStyle(() => {
    return {
      opacity: opacity.value,
      transform: [
        { scale: scale.value },
        { rotate: `${rotation.value * 360}deg` },
      ],
    };
  });

  return (
    <AnimatedLinearGradient
      colors={
        colorProgress.value < 0.5
          ? ["#1A1B4B", "#4B2B63"] // More vibrant primary colors
          : ["#2C4870", "#703B4B"] // More vibrant secondary colors
      }
      style={[styles.gradient, animatedStyle]}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
    />
  );
};

const styles = StyleSheet.create({
  gradient: {
    position: "absolute",
    width: width * 1.5, // Even larger to accommodate more dramatic scaling
    height: height * 1.5,
    left: -width * 0.25,
    top: -height * 0.25,
  },
});
