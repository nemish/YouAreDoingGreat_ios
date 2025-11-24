// FancyButtonInOut.tsx
import React from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import Animated, {
  interpolateColor,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";

export default function FancyButtonInOut({ onPress }: { onPress: () => void }) {
  const translateY = useSharedValue(0);
  const rippleOpacity = useSharedValue(0);
  const rippleScale = useSharedValue(0);
  const rippleColor = useSharedValue(0);

  const animatedStyle = useAnimatedStyle(() => ({
    transform: [{ translateY: translateY.value }],
  }));

  const rippleStyle = useAnimatedStyle(() => ({
    opacity: rippleOpacity.value,
    transform: [{ scale: rippleScale.value }],
    backgroundColor: interpolateColor(
      rippleColor.value,
      [0, 1],
      ["rgba(0, 0, 0, 0)", "rgba(0, 0, 0, 0.5)"]
    ),
  }));

  const handlePressIn = () => {
    translateY.value = withTiming(4, { duration: 200 }); // Move button down
    rippleOpacity.value = withTiming(0.3, { duration: 300 }); // Show ripple
    rippleScale.value = withTiming(1.5, { duration: 300 }); // Scale ripple
    rippleColor.value = withTiming(1, { duration: 300 }); // Change ripple color
  };

  const handlePressOut = () => {
    translateY.value = withTiming(0, { duration: 200 }); // Reset button position
    rippleOpacity.value = withTiming(0, { duration: 300 }); // Hide ripple
    rippleScale.value = withTiming(0, { duration: 300 }); // Reset ripple scale
    rippleColor.value = withTiming(0, { duration: 300 }); // Reset ripple color
    onPress();
  };

  return (
    <Pressable onPressIn={handlePressIn} onPressOut={handlePressOut}>
      <Animated.View style={styles.container}>
        <View style={styles.base} />
        <Animated.View style={[styles.button, animatedStyle]}>
          <Animated.View style={[styles.ripple, rippleStyle]} />
          <Text style={styles.text}>I Did a Thing</Text>
        </Animated.View>
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    justifyContent: "center",
    alignItems: "center",
  },
  base: {
    position: "absolute",
    width: 200,
    height: 60,
    borderRadius: 15,
    // backgroundColor: "#cc2952", // Darker shade for the base
    backgroundColor: "#991f3e", // Even darker shade for the base
    top: 9, // Position the base slightly below the button
  },
  button: {
    width: 200,
    height: 60,
    borderRadius: 15,
    backgroundColor: "#ff3366",
    justifyContent: "center",
    alignItems: "center",
    overflow: "hidden", // Ensure ripple effect is contained within the button
  },
  ripple: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 15,
  },
  text: {
    color: "white",
    fontSize: 20,
    fontWeight: "600",
    fontFamily: "Nunito",
  },
});
