import {
  BlurMask,
  Canvas,
  Circle,
  Group,
  RadialGradient,
  vec,
} from "@shopify/react-native-skia";
import React, { useEffect, useMemo } from "react";
import { Dimensions, StyleSheet, View } from "react-native";
import {
  Easing,
  useDerivedValue,
  useSharedValue,
  withRepeat,
  withSequence,
  withTiming,
} from "react-native-reanimated";
import CometAnimationSkia from "./CometAnimationSkia";

const { width, height } = Dimensions.get("window");

type BlobConfig = {
  id: number;
  x: number;
  y: number;
  baseRadius: number;
  color: string;
  duration: number;
  delay: number;
  orbitRadius: number;
  orbitSpeed: number;
  orbitPhase: number;
  morphIntensity: number;
  morphSpeed: number;
  depth: number;
};

// Rich color palette
const BLOB_COLORS = [
  { primary: "#ff3366", secondary: "#ff5580" },
  { primary: "#991f3e", secondary: "#cc3d66" },
  { primary: "#ff4d7a", secondary: "#ff8fab" },
  { primary: "#cc2952", secondary: "#ff5580" },
];

const random = (min: number, max: number) => Math.random() * (max - min) + min;

const createBlobs = (): BlobConfig[] => {
  return Array.from({ length: 5 }, (_, i) => {
    const depth = random(0.4, 1);
    const colorSet = BLOB_COLORS[Math.floor(random(0, BLOB_COLORS.length))];

    return {
      id: i,
      x: random(width * 0.1, width * 0.9),
      y: random(height * 0.1, height * 0.9),
      baseRadius: random(90, 150) * depth,
      color: i % 2 === 0 ? colorSet.primary : colorSet.secondary,
      duration: random(12000, 20000) / depth,
      delay: i * 700,
      orbitRadius: random(50, 110) * depth,
      orbitSpeed: random(0.7, 1.3),
      orbitPhase: random(0, Math.PI * 2),
      morphIntensity: random(0.25, 0.45),
      morphSpeed: random(1.3, 2.2),
      depth,
    };
  });
};

const BLOBS = createBlobs();

type AnimatedBlobProps = {
  blob: BlobConfig;
};

const AnimatedBlob = React.memo(({ blob }: AnimatedBlobProps) => {
  const progress = useSharedValue(0);
  const morphProgress = useSharedValue(0);

  useEffect(() => {
    const timeout = setTimeout(() => {
      progress.value = withRepeat(
        withTiming(1, {
          duration: blob.duration,
          easing: Easing.inOut(Easing.sin),
        }),
        -1,
        true
      );
    }, blob.delay);

    const morphTimeout = setTimeout(() => {
      morphProgress.value = withRepeat(
        withSequence(
          withTiming(1, {
            duration: blob.duration * blob.morphSpeed * 0.6,
            easing: Easing.bezier(0.42, 0, 0.58, 1),
          }),
          withTiming(-1, {
            duration: blob.duration * blob.morphSpeed * 0.4,
            easing: Easing.bezier(0.42, 0, 0.58, 1),
          })
        ),
        -1,
        false
      );
    }, blob.delay + 400);

    return () => {
      clearTimeout(timeout);
      clearTimeout(morphTimeout);
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Figure-8 orbital motion
  const cx = useDerivedValue(() => {
    const angle =
      progress.value * Math.PI * 2 * blob.orbitSpeed + blob.orbitPhase;
    const orbitX = Math.sin(angle) * blob.orbitRadius;
    const figure8 = Math.sin(angle * 2) * blob.orbitRadius * 0.4;
    return blob.x + orbitX + figure8 * 0.3;
  });

  const cy = useDerivedValue(() => {
    const angle =
      progress.value * Math.PI * 2 * blob.orbitSpeed + blob.orbitPhase;
    const figure8Y = Math.sin(angle * 2) * blob.orbitRadius * 0.4;
    const drift = Math.cos(angle * 0.4) * blob.orbitRadius * 0.25;
    return blob.y + figure8Y + drift;
  });

  // Organic morphing with multiple frequencies
  const radius = useDerivedValue(() => {
    const wave1 =
      Math.sin(morphProgress.value * Math.PI * 3) * blob.morphIntensity;
    const wave2 =
      Math.cos(morphProgress.value * Math.PI * 5) * blob.morphIntensity * 0.5;
    const totalMorph = (wave1 + wave2) * blob.baseRadius;
    return blob.baseRadius + totalMorph;
  });

  // Elliptical distortion
  const radiusX = useDerivedValue(() => {
    const squeeze = Math.sin(morphProgress.value * Math.PI * 4) * 0.18;
    return radius.value * (1 + squeeze);
  });

  const radiusY = useDerivedValue(() => {
    const squeeze = Math.cos(morphProgress.value * Math.PI * 4) * 0.18;
    return radius.value * (1 - squeeze * 0.5);
  });

  const center = useDerivedValue(() => vec(cx.value, cy.value));

  // Dynamic opacity for depth
  const opacity = useDerivedValue(() => {
    const variation = Math.sin(progress.value * Math.PI * 2) * 0.08;
    return blob.depth * 0.5 + 0.2 + variation;
  });

  return (
    <Group>
      {/* Outer atmospheric glow */}
      <Circle cx={cx} cy={cy} r={radiusX} opacity={opacity}>
        <RadialGradient
          c={center}
          r={radiusX}
          colors={[
            `${blob.color}50`,
            `${blob.color}28`,
            `${blob.color}10`,
            "transparent",
          ]}
          positions={[0, 0.45, 0.75, 1]}
        />
        <BlurMask blur={45} style="solid" />
      </Circle>

      {/* Main glow body */}
      {/* <Circle cx={cx} cy={cy} r={radiusY} opacity={opacity}>
        <RadialGradient
          c={center}
          r={radiusY}
          colors={[
            `${blob.color}90`,
            `${blob.color}60`,
            `${blob.color}25`,
            "transparent",
          ]}
          positions={[0.2, 0.55, 0.85, 1]}
        />
        <BlurMask blur={25} style="solid" />
      </Circle> */}

      {/* Core highlight */}
      {/* <Circle cx={cx} cy={cy} r={radius} opacity={opacity}>
        <RadialGradient
          c={center}
          r={radius}
          colors={[
            `${blob.color}DD`,
            `${blob.color}88`,
            "transparent",
          ]}
          positions={[0.35, 0.75, 1]}
        />
        <BlurMask blur={10} style="solid" />
      </Circle> */}
    </Group>
  );
});

AnimatedBlob.displayName = "AnimatedBlob";

type Props = {
  isPanning: boolean;
};

export const AnimatedBlobsBackground = ({ isPanning }: Props) => {
  const blobElements = useMemo(
    () => BLOBS.map((blob) => <AnimatedBlob key={blob.id} blob={blob} />),
    []
  );

  return (
    <View style={styles.container}>
      <View style={styles.darkBackground} />
      <Canvas style={StyleSheet.absoluteFill}>{blobElements}</Canvas>
      <CometAnimationSkia />
      <View style={styles.overlay} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    width: width,
    height: height,
    overflow: "hidden",
  },
  darkBackground: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "#0f1219",
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(10, 12, 18, 0.2)",
  },
});
