import { useEffect, useState } from "react";
import { Dimensions } from "react-native";
import { Gesture } from "react-native-gesture-handler";
import { useSharedValue, withTiming } from "react-native-reanimated";

type Args = {
  isPressed: boolean;
};

const height = Dimensions.get("window").height;

const useExpandAnimation = ({ isPressed }: Args) => {
  const translateY = useSharedValue(0);
  const [isExpanded, setIsExpanded] = useState(false);

  useEffect(() => {
    if (isPressed) {
      return;
    }

    if (isExpanded) {
      translateY.value = withTiming(-height * 0.15, { duration: 300 });
    } else {
      translateY.value = withTiming(0, { duration: 300 });
    }
  }, [isExpanded, isPressed]);

  const swipeGesture = Gesture.Pan()
    .onUpdate((event) => {
      if (isPressed) {
        return;
      }
      if (isExpanded) {
        if (event.translationY < 0) {
          return;
        }
        translateY.value = withTiming(event.translationY, { duration: 300 });
        if (event.translationY < 50) {
          console.log("collapse");
          // runOnJS(setIsExpanded)(false);
        }
      } else {
        if (event.translationY > 0) {
          return;
        }
        translateY.value = withTiming(event.translationY, { duration: 300 });
        if (event.translationY < -50) {
          console.log("expand");
          // runOnJS(setIsExpanded)(true);
        }
      }
    })
    .onEnd(() => {
      if (isExpanded || isPressed) {
      } else {
        translateY.value = withTiming(0, { duration: 300 });
      }
    });

  return { translateY, swipeGesture, isExpanded };
};

export default useExpandAnimation;
