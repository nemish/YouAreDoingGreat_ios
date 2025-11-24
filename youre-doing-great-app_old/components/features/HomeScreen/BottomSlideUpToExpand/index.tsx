import { RawThemedText } from "@/components/RawThemedText";
import Icon from "@/components/ui/LucideIcon";
import { MotiView } from "moti";
import { useEffect } from "react";
import { StyleSheet } from "react-native";
import Animated, {
  useAnimatedStyle,
  useSharedValue,
  withRepeat,
  withTiming,
} from "react-native-reanimated";

type Props = {
  isExpanded: boolean;
  isPressed: boolean;
};

const BottomSlideUpToExpand = ({ isExpanded, isPressed }: Props) => {
  const bottomTextAnim = useSharedValue(0);
  const bottomTextOpacityAnim = useSharedValue(0);

  useEffect(() => {
    bottomTextAnim.value = withRepeat(
      withTiming(1, { duration: 3000 }),
      -1,
      true
    );
  }, []);

  useEffect(() => {
    if (isPressed) {
      return;
    }

    if (isExpanded) {
      bottomTextOpacityAnim.value = withTiming(0, { duration: 1000 });
    } else {
      bottomTextOpacityAnim.value = withRepeat(
        withTiming(1, { duration: 6000 }),
        -1,
        true
      );
    }
  }, [isExpanded, isPressed]);

  const bottomTextAnimatedStyle = useAnimatedStyle(() => {
    const opacity =
      0.5 - 0.3 * (1 - Math.abs(bottomTextOpacityAnim.value - 0.5) * 2);
    const translateY = -5 + 10 * bottomTextAnim.value;
    return {
      opacity,
      transform: [{ translateY }],
    };
  });
  return (
    <MotiView
      style={styles.bottomTextContainer}
      from={{ opacity: 0, translateY: -20 }}
      animate={{ opacity: 1, translateY: 0 }}
      exit={{ opacity: 0, translateY: -20 }}
      transition={{
        type: "timing",
        duration: 500,
      }}
    >
      <Animated.View
        className={`flex flex-col items-center justify-center relative`}
        style={[bottomTextAnimatedStyle]}
      >
        <Icon name={"chevrons-up"} size={14} color={"white"} />
        <RawThemedText>swipe up to expand</RawThemedText>
      </Animated.View>
    </MotiView>
  );
};

const styles = StyleSheet.create({
  bottomTextContainer: {
    position: "absolute",
    bottom: 40,
    width: "100%",
    display: "flex",
    justifyContent: "center",
    alignItems: "center",
  },
});

export default BottomSlideUpToExpand;
