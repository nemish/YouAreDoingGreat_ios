// FancyButton.tsx
import classnames from "classnames";
import React, { useEffect, useRef, useState } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import Animated, {
  Easing,
  interpolateColor,
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withDelay,
  withTiming,
} from "react-native-reanimated";

const BUTTON_COLORS = {
  default: {
    button: "#ff3366",
    shadow: "#991f3e",
  },
  strawberry: {
    button: "#FF5A7D",
    shadow: "#B03658",
  },
  warmEvening: {
    button: "#FF7A6E",
    shadow: "#C05045",
  },
  softMorning: {
    button: "#D96C90",
    shadow: "#97445E",
  },
  friendlyFire: {
    button: "#FF7660",
    shadow: "#B34738",
  },
  sugarWaltz: {
    button: "#F68CA9",
    shadow: "#A44F65",
  },
  oceanBlue: {
    button: "#0EA5E9",
    shadow: "#0284C7",
  },
};

const PADDING_MAP = {
  // sm: "px-4 py-2",
  // base: "px-8 py-4",
  // lg: "px-10 py-4",
  // xl: "px-16 py-8",
  sm: "py-2",
  base: "py-4",
  lg: "py-4",
  xl: "py-8",
};

const TEXT_SIZE_MAP = {
  sm: "text-lg",
  base: "text-xl",
  lg: "text-2xl",
  xl: "text-3xl",
};

const ROUNDING_MAP = {
  sm: "rounded-md",
  base: "rounded-lg",
  lg: "rounded-xl",
  xl: "rounded-2xl",
};

type Props = {
  onPress: () => void;
  isDisabled?: boolean;
  kind?: keyof typeof BUTTON_COLORS;
  text?: string;
  fullWidth?: boolean;
  size?: keyof typeof PADDING_MAP;
  className?: string;
};

const PADDING_OFFSET = 50;

export default function FancyButton({
  onPress,
  isDisabled,
  kind,
  text,
  fullWidth,
  size = "xl",
  className,
}: Props) {
  const translateY = useSharedValue(0);
  const rippleOpacity = useSharedValue(0);
  const rippleScale = useSharedValue(0);
  const rippleColor = useSharedValue(0);
  const textOpacity = useSharedValue(1);

  // --- Animated width logic ---
  const [measuredWidth, setMeasuredWidth] = useState(0);
  const [displayText, setDisplayText] = useState(text);
  // const [isAnimating, setIsAnimating] = useState(false);
  const width = useSharedValue(0);
  const prevTextRef = useRef<string | undefined>(text);

  useEffect(() => {
    if (measuredWidth > 0 && !fullWidth) {
      width.value = withTiming(measuredWidth + PADDING_OFFSET, {
        duration: 600,
        // easing: Easing.inOut(Easing.quad),
        // easing: Easing.quad,
        easing: Easing.out(Easing.quad),
      });
    }
  }, [measuredWidth, fullWidth]);

  // If text changes, fade out, change text, then fade in
  useEffect(() => {
    const updateText = () => {
      setDisplayText(text);
      setMeasuredWidth(0);
      prevTextRef.current = text;
      textOpacity.value = withDelay(50, withTiming(1, { duration: 400 }));
    };

    if (prevTextRef.current !== text) {
      textOpacity.value = withTiming(0, { duration: 400 }, (finished) => {
        if (finished) {
          runOnJS(updateText)();
        }
      });
    }
  }, [text, textOpacity]);

  // Animated style for width
  const animatedWidthStyle = useAnimatedStyle(() => {
    return fullWidth ? {} : { width: width.value };
  });

  const animatedTextStyle = useAnimatedStyle(() => ({
    opacity: textOpacity.value,
    transform: [
      {
        // translateY: textOpacity.value > 0 ? 0 : textOpacity.value * 100,
        translateY: textOpacity.value === 0 ? -4 : -4 + textOpacity.value * 4,
      },
    ],
  }));
  // --- End animated width logic ---

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

  const handlePress = () => {
    // Trigger press in animations
    translateY.value = withTiming(4, { duration: 100 });
    rippleOpacity.value = withTiming(0.3, { duration: 200 });
    rippleScale.value = withTiming(1.5, { duration: 200 });
    rippleColor.value = withTiming(1, { duration: 200 });

    // Trigger press out animations after a delay
    setTimeout(() => {
      translateY.value = withTiming(0, { duration: 100 });
      rippleOpacity.value = withTiming(0, { duration: 200 });
      rippleScale.value = withTiming(0, { duration: 200 });
      rippleColor.value = withTiming(0, { duration: 200 });
      onPress();
    }, 200); // Delay to allow press in animations to complete
  };

  const { button, shadow } = BUTTON_COLORS[kind || "default"];

  return (
    <Pressable onPress={handlePress} disabled={isDisabled}>
      <Animated.View style={styles.container} className={className}>
        {/* Hidden text for measuring width */}
        {!fullWidth && (
          <Text
            style={[
              styles.text,
              {
                position: "absolute",
                opacity: 0,
                left: -9999,
                fontFamily: "Nunito",
              },
            ]}
            className={TEXT_SIZE_MAP[size]}
            numberOfLines={1}
            onLayout={(e) => {
              if (measuredWidth === 0) {
                setMeasuredWidth(e.nativeEvent.layout.width);
              }
            }}
          >
            {displayText || "I Did a Thing"}
          </Text>
        )}
        <View
          style={[{ backgroundColor: shadow }]}
          className={classnames(
            "w-full h-full",
            ROUNDING_MAP[size],
            "absolute left-0",
            size === "sm" ? "top-1" : "top-1"
          )}
        />
        <Animated.View
          style={[
            styles.button,
            animatedStyle,
            { backgroundColor: button },
            animatedWidthStyle,
          ]}
          className={classnames(
            fullWidth && "w-full",
            PADDING_MAP[size],
            ROUNDING_MAP[size]
          )}
        >
          <Animated.View style={[styles.ripple, rippleStyle]} />
          <Animated.Text
            style={[styles.text, animatedTextStyle, styles.noWrapText]}
            className={TEXT_SIZE_MAP[size]}
            numberOfLines={1}
          >
            {displayText || "I Did a Thing"}
          </Animated.Text>
        </Animated.View>
      </Animated.View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  container: {
    justifyContent: "center",
    alignItems: "center",
    wordWrap: "nowrap",
  },
  base: {},
  button: {
    // borderRadius: 15,
    justifyContent: "center",
    alignItems: "center",
    overflow: "hidden", // Ensure ripple effect is contained within the button
  },
  ripple: {
    ...StyleSheet.absoluteFillObject,
    borderRadius: 15,
  },
  text: {
    color: "#ffd6e0",
    fontFamily: "Comfortaa",
    fontWeight: "900",
    // textShadowColor: "#7a001f",
    textShadowOffset: { width: 0, height: 0 },
    textShadowRadius: 1,
  },
  noWrapText: {
    flexShrink: 0,
    flexWrap: "nowrap",
    overflow: "hidden",
  },
});
