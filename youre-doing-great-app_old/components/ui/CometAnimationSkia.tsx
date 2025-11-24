import {
  BlurMask,
  Canvas,
  Circle,
  Group,
  LinearGradient,
  Path,
  RadialGradient,
  Skia,
  vec,
} from "@shopify/react-native-skia";
import React, { useEffect, useState } from "react";
import { Dimensions, StyleSheet } from "react-native";
import {
  runOnJS,
  useDerivedValue,
  useSharedValue,
  withTiming,
} from "react-native-reanimated";

const { width, height } = Dimensions.get("window");

const random = (min: number, max: number) => Math.random() * (max - min) + min;

const COMET_COLORS = [
  { head: "#ffffff", tail: "#ffffff" },
  { head: "#e0f7ff", tail: "#aeefff" },
  { head: "#eaffea", tail: "#baffc9" },
  { head: "#fff0fa", tail: "#ffd6fa" },
  { head: "#fffbe0", tail: "#ffe680" },
  { head: "#e0f0ff", tail: "#b0d0ff" },
  { head: "#f8fafd", tail: "#e0f7ff" },
  { head: "#fff6e0", tail: "#ffe0b3" },
];

const MAX_COMETS = 3;

function createComet() {
  // Restrict angle to max 60 degrees from horizontal
  const fromLeft = Math.random() < 0.5;
  const yRange = height * 0.8;
  const yMin = height * 0.1;
  const startY = random(yMin, yMin + yRange);
  const angleDeg = random(-60, 60);
  const angleRad = angleDeg * (Math.PI / 180);
  const travel = width + 120;
  const deltaY = Math.tan(angleRad) * travel * (fromLeft ? 1 : -1);
  const endY = startY + deltaY;
  const startX = fromLeft ? -60 : width + 60;
  const endX = fromLeft ? width + 60 : -60;
  const endYClamped = Math.max(-60, Math.min(height + 60, endY));
  const size = random(4, 8);
  const tailLength = random(16, 32);
  const color = COMET_COLORS[Math.floor(random(0, COMET_COLORS.length))];
  const duration = random(1800, 3500);
  const angle = Math.atan2(endYClamped - startY, endX - startX);
  return {
    id: Math.random().toString(36).slice(2),
    startX,
    startY,
    endX,
    endY: endYClamped,
    size,
    tailLength,
    color,
    duration,
    angle,
  };
}

const CometSkia = ({
  comet,
  onDone,
}: {
  comet: ReturnType<typeof createComet>;
  onDone: () => void;
}) => {
  // --- Performance optimised animation (runs on the UI thread) ---
  const progress = useSharedValue(0);

  // Kick-off timing animation once on mount.
  useEffect(() => {
    progress.value = withTiming(1, { duration: comet.duration }, (finished) => {
      if (finished) {
        // `onDone` lives on the JS thread – bridge back once animation completes.
        runOnJS(onDone)();
      }
    });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Derived x / y positions for current animation frame – evaluated on UI thread.
  const x = useDerivedValue(
    () => comet.startX + (comet.endX - comet.startX) * progress.value
  );
  const y = useDerivedValue(
    () => comet.startY + (comet.endY - comet.startY) * progress.value
  );

  // Tail path updates every frame on the UI thread without triggering React re-renders.
  const tailPath = useDerivedValue(() => {
    const p = Skia.Path.Make();
    const tailStartX = x.value;
    const tailStartY = y.value;
    const tailEndX = tailStartX - Math.cos(comet.angle) * comet.tailLength;
    const tailEndY = tailStartY - Math.sin(comet.angle) * comet.tailLength;
    p.moveTo(tailStartX, tailStartY);
    p.lineTo(tailEndX, tailEndY);
    return p;
  });

  // Gradient vectors following head movement.
  const gradStart = useDerivedValue(() => vec(x.value, y.value));
  const gradEnd = useDerivedValue(() =>
    vec(
      x.value - Math.cos(comet.angle) * comet.tailLength,
      y.value - Math.sin(comet.angle) * comet.tailLength
    )
  );

  // Tapered tail: draw two strokes, wide and narrow, for a soft taper
  const headWidth = comet.size * 0.8;
  const tailWidth = comet.size * 0.25;

  return (
    <>
      {/* Tail (gradient, blurred, wide base) */}
      <Path
        path={tailPath}
        style="stroke"
        strokeWidth={headWidth}
        strokeCap="round"
      >
        <LinearGradient
          start={gradStart}
          end={gradEnd}
          colors={[
            `${comet.color.head}44`, // more transparent
            `${comet.color.tail}22`,
            "transparent",
          ]}
          positions={[0, 0.7, 1]}
        />
        <BlurMask blur={comet.size * 1.2} style="solid" />
      </Path>
      {/* Tail (narrow, more visible core) */}
      <Path
        path={tailPath}
        style="stroke"
        strokeWidth={tailWidth}
        strokeCap="round"
      >
        <LinearGradient
          start={gradStart}
          end={gradEnd}
          colors={[
            `${comet.color.head}88`, // more transparent
            `${comet.color.tail}44`,
            "transparent",
          ]}
          positions={[0, 0.7, 1]}
        />
        <BlurMask blur={comet.size * 0.5} style="solid" />
      </Path>
      {/* Head glow (radial gradient, blurred) */}
      <Circle cx={x} cy={y} r={comet.size * 2.5}>
        <RadialGradient
          c={gradStart}
          r={comet.size * 2.5}
          colors={[
            `${comet.color.head}33`,
            `${comet.color.head}11`,
            "transparent",
          ]}
          positions={[0, 0.7, 1]}
        />
        <BlurMask blur={comet.size * 1.2} style="solid" />
      </Circle>
      {/* Head (radial gradient core) */}
      <Circle cx={x} cy={y} r={comet.size / 2}>
        <RadialGradient
          c={gradStart}
          r={comet.size / 2}
          colors={[comet.color.head, `${comet.color.head}66`, "transparent"]}
          positions={[0, 0.7, 1]}
        />
      </Circle>
    </>
  );
};

const CometAnimationSkia = () => {
  const [comets, setComets] = useState<ReturnType<typeof createComet>[]>([]);
  // Spawn comets at intervals
  useEffect(() => {
    let isMounted = true;
    let timeout: ReturnType<typeof setTimeout>;
    const loop = () => {
      if (!isMounted) return;
      setComets((prev) => {
        if (prev.length >= MAX_COMETS) return prev;
        return [...prev, createComet()];
      });
      timeout = setTimeout(loop, random(5000, 10000));
    };
    loop();
    return () => {
      isMounted = false;
      clearTimeout(timeout);
    };
  }, []);
  // Remove comet when done
  const handleDone = (id: string) => {
    setComets((prev) => prev.filter((c) => c.id !== id));
  };
  return (
    <Canvas style={StyleSheet.absoluteFill}>
      {comets.map((comet) => (
        <Group key={comet.id}>
          <CometSkia comet={comet} onDone={() => handleDone(comet.id)} />
        </Group>
      ))}
    </Canvas>
  );
};

export default CometAnimationSkia;
