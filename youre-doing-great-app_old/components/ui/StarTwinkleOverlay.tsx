import React from "react";
import { Dimensions, StyleSheet, View } from "react-native";
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";

const { width, height } = Dimensions.get("window");

// Soft star colors: whites, blues, yellows, pinks
const STAR_COLORS = [
  "#fff",
  "#ffe9c4",
  "#d4fbff",
  "#fff6e0",
  "#e0f7ff",
  "#fff0fa",
  "#f8fafd",
  "#fffbe0",
  "#eaffea",
  "#e0f0ff",
];

const STAR_COUNT = 50;

function random(min: number, max: number) {
  return Math.random() * (max - min) + min;
}

// Generate star data once
const stars = Array.from({ length: STAR_COUNT }).map(() => {
  const size = random(1.5, 3.5);
  return {
    left: random(0, width),
    top: random(0, height),
    size,
    color: STAR_COLORS[Math.floor(random(0, STAR_COLORS.length))],
  };
});

// Custom hook for hectic twinkle
function useHecticTwinkle(minOpacity = 0.2, maxOpacity = 1) {
  const opacity = useSharedValue(random(minOpacity, maxOpacity));
  const timeoutRef = React.useRef<NodeJS.Timeout | null>(null);

  const animate = React.useCallback(() => {
    const nextOpacity = random(minOpacity, maxOpacity);
    const duration = random(100, 400); // fast, random interval
    opacity.value = withTiming(nextOpacity, { duration }, () => {
      // Schedule next twinkle
      runOnJS(scheduleNext)();
    });
  }, []);

  const scheduleNext = React.useCallback(() => {
    // No delay, just immediately animate again
    animate();
  }, [animate]);

  React.useEffect(() => {
    animate();
    return () => {
      if (timeoutRef.current) clearTimeout(timeoutRef.current);
    };
  }, []);

  return opacity;
}

export const StarTwinkleOverlay = () => {
  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {stars.map((star, i) => {
        const opacity = useHecticTwinkle(0.2, 1);
        const animatedStyle = useAnimatedStyle(() => ({
          opacity: opacity.value,
        }));
        return (
          <Animated.View
            key={i}
            style={[
              styles.star,
              {
                left: star.left,
                top: star.top,
                width: star.size,
                height: star.size,
                borderRadius: star.size / 2,
                backgroundColor: star.color,
                shadowColor: star.color,
                shadowOpacity: 0.8,
                shadowRadius: star.size * 2,
                shadowOffset: { width: 0, height: 0 },
              },
              animatedStyle,
            ]}
          />
        );
      })}
    </View>
  );
};

const styles = StyleSheet.create({
  star: {
    position: "absolute",
  },
});

export default StarTwinkleOverlay;
