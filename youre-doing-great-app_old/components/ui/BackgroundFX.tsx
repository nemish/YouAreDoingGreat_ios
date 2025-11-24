import React, { useEffect, useState } from "react";
import { Dimensions, StyleSheet, View } from "react-native";
// import LinearGradient from "react-native-linear-gradient";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import Animated, {
  Easing,
  useAnimatedProps,
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";
import Svg, { Defs, RadialGradient, Rect, Stop } from "react-native-svg";
import CometAnimationSkia from "./CometAnimationSkia";

const { width, height } = Dimensions.get("window");

// const img = require("@/assets/images/bg-2.jpg");
// const img = require("@/assets/images/bg-2-min.jpg");
const img = require("@/assets/images/bg-2.webp");
// const img = require("@/assets/images/bg-4.jpg");

// Enable animated props for the SVG radial gradient
const AnimatedRadialGradient = Animated.createAnimatedComponent(RadialGradient);

type Props = {
  isPanning: boolean;
};

export const BackgroundFX = ({ isPanning }: Props) => {
  const isInitMomentPanelShown = useMainPanelStore(
    (state) => state.isInitMomentPanelShown
  );
  // Animate scale, translateX, and translateY
  const scale = useSharedValue(1);
  const translateX = useSharedValue(0);
  const translateY = useSharedValue(0);

  // Track when the background image has finished loading
  const [imageLoaded, setImageLoaded] = useState(false);

  // Shared value for the breathing gradient radius (percentage string without "%")
  const gradientRadius = useSharedValue(50);

  // Animated props for the radial gradient (rx / ry)
  const animatedGradientProps = useAnimatedProps(() => ({
    rx: `${gradientRadius.value}%`,
    ry: `${gradientRadius.value}%`,
  }));

  // Helper to get a random value in a range
  const getRandom = (min: number, max: number) =>
    Math.random() * (max - min) + min;

  const shouldAnimate = isInitMomentPanelShown && !isPanning;

  useEffect(() => {
    let isMounted = true;
    if (!shouldAnimate) return;

    const animate = () => {
      if (!isMounted) return;

      // Randomize next values
      const nextScale = getRandom(1, 1.1);
      const nextTranslateX = getRandom(-10, 10);
      const nextTranslateY = getRandom(-10, 10);

      // Animate to next values
      scale.value = withTiming(nextScale, { duration: 8000 });
      translateX.value = withTiming(nextTranslateX, { duration: 8000 });
      translateY.value = withTiming(nextTranslateY, { duration: 8000 });

      // Schedule next animation after current one finishes
      setTimeout(animate, 8000);
    };

    animate();

    return () => {
      isMounted = false;
    };
  }, [shouldAnimate]);

  // Start a smooth breathing animation for the gradient radius
  useEffect(() => {
    if (!shouldAnimate) return;
    gradientRadius.value = withRepeat(
      withTiming(60, {
        duration: 6000,
        easing: Easing.inOut(Easing.ease),
      }),
      -1,
      true // reverse on repeat
    );
  }, [shouldAnimate]);

  // Animated style for the image
  const animatedStyle = useAnimatedStyle(() => ({
    transform: [
      { scale: scale.value },
      { translateX: translateX.value },
      { translateY: translateY.value },
    ],
  }));

  return (
    <View style={styles.container}>
      <Animated.Image
        source={img}
        resizeMode="cover"
        style={[styles.lottie, animatedStyle]}
        onLoadEnd={() => setImageLoaded(true)}
      />

      {/* Render gradient and FX only after the image is ready to avoid an initial flash */}
      {imageLoaded && (
        <>
          <Svg
            pointerEvents="none"
            style={StyleSheet.absoluteFill}
            width={width}
            height={height}
          >
            <Defs>
              <AnimatedRadialGradient
                animatedProps={animatedGradientProps}
                id="grad"
                cx="50%"
                cy="50%"
                fx="50%"
                fy="50%"
              >
                <Stop offset="0%" stopColor="black" stopOpacity="0" />
                <Stop offset="60%" stopColor="black" stopOpacity="0" />
                <Stop offset="100%" stopColor="black" stopOpacity="0.5" />
              </AnimatedRadialGradient>
            </Defs>
            <Rect x="0" y="0" width={width} height={height} fill="url(#grad)" />
          </Svg>
          {shouldAnimate && <CometAnimationSkia />}
          <View style={styles.overlay} />
        </>
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    width: width,
    height: height,
    overflow: "hidden",
    // opacity: 0.5,
  },
  lottie: {
    position: "absolute",
    width: width,
    height: height,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(18, 20, 24, 0.5)", // вот она, занавесочка
  },
});
