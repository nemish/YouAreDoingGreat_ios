import React, { useEffect, useState } from "react";
import { Dimensions, StyleSheet, View } from "react-native";
import Animated, {
  runOnJS,
  useAnimatedStyle,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";
import Svg, {
  Defs,
  Ellipse,
  G,
  LinearGradient,
  RadialGradient,
  Stop,
} from "react-native-svg";

const { width, height } = Dimensions.get("window");

// Helper to generate a random number in a range
const random = (min: number, max: number) => Math.random() * (max - min) + min;

const COMET_COLORS = [
  { head: "#ffffff", tail: "#ffffff" }, // pure white
  { head: "#e0f7ff", tail: "#aeefff" }, // icy blue
  { head: "#eaffea", tail: "#baffc9" }, // pale green
  { head: "#fff0fa", tail: "#ffd6fa" }, // soft pink
  { head: "#fffbe0", tail: "#ffe680" }, // gold
  { head: "#e0f0ff", tail: "#b0d0ff" }, // blue-white
  { head: "#f8fafd", tail: "#e0f7ff" }, // near-white blue
  { head: "#fff6e0", tail: "#ffe0b3" }, // warm white
];

const GLOW_RADIUS = 60; // px, for head glow
const TAIL_RADIUS = 80; // px, for tail

const CometSVG = ({
  size,
  tailLength,
  color,
  angle,
}: {
  size: number;
  tailLength: number;
  color: { head: string; tail: string };
  angle: number;
}) => {
  // The head is always at (CENTER, CENTER) in the SVG
  const CENTER = GLOW_RADIUS + size;
  const WIDTH = CENTER + tailLength + TAIL_RADIUS;
  const HEIGHT = CENTER * 2;
  return (
    <Svg
      width={WIDTH}
      height={HEIGHT}
      style={{
        transform: [{ rotate: `${angle}deg` }],
      }}
    >
      <Defs>
        <LinearGradient
          id="tailGradient"
          x1={CENTER}
          y1={CENTER}
          x2={CENTER - tailLength}
          y2={CENTER}
        >
          <Stop offset="0%" stopColor={color.tail} stopOpacity="0.0" />
          <Stop offset="30%" stopColor={color.tail} stopOpacity="0.18" />
          <Stop offset="70%" stopColor={color.tail} stopOpacity="0.35" />
          <Stop offset="100%" stopColor={color.tail} stopOpacity="0.7" />
        </LinearGradient>
        <RadialGradient id="tailCore" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={color.tail} stopOpacity="0.45" />
          <Stop offset="70%" stopColor={color.tail} stopOpacity="0.13" />
          <Stop offset="100%" stopColor={color.tail} stopOpacity="0" />
        </RadialGradient>
        <RadialGradient id="headGlow" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={color.head} stopOpacity="0.22" />
          <Stop offset="85%" stopColor={color.head} stopOpacity="0.08" />
          <Stop offset="100%" stopColor={color.head} stopOpacity="0" />
        </RadialGradient>
        <RadialGradient id="headGlowLarge" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={color.head} stopOpacity="0.08" />
          <Stop offset="100%" stopColor={color.head} stopOpacity="0" />
        </RadialGradient>
        <RadialGradient id="headCore" cx="50%" cy="50%" r="50%">
          <Stop offset="0%" stopColor={color.head} stopOpacity="0.85" />
          <Stop offset="80%" stopColor={color.head} stopOpacity="0.3" />
          <Stop offset="100%" stopColor={color.head} stopOpacity="0" />
        </RadialGradient>
      </Defs>
      <G>
        {/* Tapered, blurred tail (ellipse, wide near head, narrow at end) */}
        <Ellipse
          cx={CENTER - tailLength / 2}
          cy={CENTER}
          rx={tailLength * 0.55}
          ry={size * 0.45}
          fill="url(#tailCore)"
          opacity={0.7}
        />
        {/* Extra blurred tail glow */}
        <Ellipse
          cx={CENTER - tailLength * 0.4}
          cy={CENTER}
          rx={tailLength * 0.7}
          ry={size * 0.9}
          fill={color.tail}
          opacity={0.13}
        />
        {/* Head glow with radial gradient */}
        <Ellipse
          cx={CENTER}
          cy={CENTER}
          rx={size * 3.8}
          ry={size * 3.8}
          fill="url(#headGlow)"
        />
        <Ellipse
          cx={CENTER}
          cy={CENTER}
          rx={size * 6.2}
          ry={size * 6.2}
          fill="url(#headGlowLarge)"
        />
        {/* Head (bright, in front) */}
        <Ellipse
          cx={CENTER}
          cy={CENTER}
          rx={size / 2}
          ry={size / 2}
          fill="url(#headCore)"
        />
      </G>
    </Svg>
  );
};

type CometProps = {
  id: number;
  startX: number;
  endX: number;
  startY: number;
  endY: number;
  size: number;
  tailLength: number;
  color: { head: string; tail: string };
  duration: number;
  angle: number;
  onDone: (id: number) => void;
};

const Comet: React.FC<CometProps> = ({
  id,
  startX,
  endX,
  startY,
  endY,
  size,
  tailLength,
  color,
  duration,
  angle,
  onDone,
}) => {
  const progress = useSharedValue(0);
  // The head should be at (x, y) on screen, so offset the container by -(CENTER, CENTER)
  const CENTER = GLOW_RADIUS + size;
  useEffect(() => {
    progress.value = withTiming(1, { duration }, (finished) => {
      if (finished) {
        runOnJS(onDone)(id);
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const animatedStyle = useAnimatedStyle(() => {
    return {
      position: "absolute",
      left: startX + (endX - startX) * progress.value - CENTER,
      top: startY + (endY - startY) * progress.value - CENTER,
      opacity: 0.85 + 0.15 * (1 - Math.abs(progress.value - 0.5) * 2),
    };
  });

  return (
    <Animated.View
      style={[
        animatedStyle,
        { width: CENTER + tailLength + TAIL_RADIUS, height: CENTER * 2 },
      ]}
      pointerEvents="none"
      shouldRasterizeIOS
      renderToHardwareTextureAndroid
    >
      <CometSVG
        size={size}
        tailLength={tailLength}
        color={color}
        angle={angle}
      />
    </Animated.View>
  );
};

type CometData = {
  id: number;
  startX: number;
  endX: number;
  startY: number;
  endY: number;
  size: number;
  tailLength: number;
  color: { head: string; tail: string };
  duration: number;
  angle: number;
};

let cometId = 0;

const CometAnimation = () => {
  const [comets, setComets] = useState<CometData[]>([]);

  // Spawn a new comet
  const spawnComet = () => {
    // Restrict angle to max 60 degrees from horizontal
    // Pick a random edge (left or right)
    const fromLeft = Math.random() < 0.5;
    const yRange = height * 0.8;
    const yMin = height * 0.1;
    const startY = random(yMin, yMin + yRange);
    // Pick an angle between -60 and +60 degrees (in radians)
    const angleDeg = random(-60, 60);
    const angleRad = angleDeg * (Math.PI / 180);
    const travel = width + 120; // travel distance (offscreen to offscreen)
    const deltaY = Math.tan(angleRad) * travel * (fromLeft ? 1 : -1);
    const endY = startY + deltaY;
    const startX = fromLeft ? -60 : width + 60;
    const endX = fromLeft ? width + 60 : -60;
    // Clamp endY to screen bounds (with some margin)
    const endYClamped = Math.max(-60, Math.min(height + 60, endY));
    const size = random(4, 8);
    const tailLength = random(16, 32);
    const color = COMET_COLORS[Math.floor(random(0, COMET_COLORS.length))];
    const duration = random(3500, 6000);
    const angle =
      Math.atan2(endYClamped - startY, endX - startX) * (180 / Math.PI);
    const id = cometId++;
    const newComet = {
      id,
      startX,
      endX,
      startY,
      endY: endYClamped,
      size,
      tailLength,
      color,
      duration,
      angle,
    };
    setComets((prev) => {
      if (prev.length >= 5) return prev;
      console.log("Spawning comet:", newComet);
      return [...prev, newComet];
    });
  };

  // Periodically spawn comets
  useEffect(() => {
    let isMounted = true;
    let timeout: ReturnType<typeof setTimeout>;
    const loop = () => {
      if (!isMounted) return;
      spawnComet();
      // Even less frequent: 5s to 10s between comets
      timeout = setTimeout(loop, random(5000, 10000));
    };
    loop();
    return () => {
      isMounted = false;
      clearTimeout(timeout);
    };
  }, []);

  // Remove comet callback
  const handleCometDone = (id: number) => {
    setComets((prev) => prev.filter((c) => c.id !== id));
  };

  return (
    <View pointerEvents="none" style={StyleSheet.absoluteFill}>
      {comets.map((comet) => (
        <Comet key={comet.id} {...comet} onDone={handleCometDone} />
      ))}
    </View>
  );
};

export default CometAnimation;
