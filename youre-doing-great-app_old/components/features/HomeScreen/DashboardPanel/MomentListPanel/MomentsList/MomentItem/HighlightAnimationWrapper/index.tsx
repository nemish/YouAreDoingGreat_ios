import { MotiView } from "moti";
import React, { useEffect, useMemo, useState } from "react";
import { StyleSheet, View } from "react-native";

type Props = {
  shouldAnimate: boolean;
  children: React.ReactNode;
};

const HighlightAnimationWrapper = React.memo(
  ({ shouldAnimate, children }: Props) => {
    const [isAnimating, setIsAnimating] = useState(false);

    useEffect(() => {
      if (shouldAnimate) {
        const timer = setTimeout(() => {
          setIsAnimating(true);
        }, 1000);

        return () => clearTimeout(timer);
      } else {
        setIsAnimating(false);
      }
    }, [shouldAnimate]);

    // Memoize the animation configuration
    const animationConfig = useMemo(
      () => ({
        animate: {
          rotate: ["0deg", "-5deg", "5deg", "0deg"],
          scale: [1, 1.04, 1.04, 1],
        },
        transition: {
          type: "timing" as const,
          duration: 500,
          loop: true,
          repeat: 2,
        },
      }),
      []
    );

    if (isAnimating) {
      return (
        <MotiView
          animate={animationConfig.animate}
          transition={animationConfig.transition}
          style={styles.container}
        >
          {children}
        </MotiView>
      );
    }

    return <View style={styles.container}>{children}</View>;
  },
  (prevProps, nextProps) => {
    // Only re-render if shouldAnimate changes
    return prevProps.shouldAnimate === nextProps.shouldAnimate;
  }
);

HighlightAnimationWrapper.displayName = "HighlightAnimationWrapper";

const styles = StyleSheet.create({
  container: {
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.3)",
    borderRadius: 12,
  },
});

export default HighlightAnimationWrapper;
