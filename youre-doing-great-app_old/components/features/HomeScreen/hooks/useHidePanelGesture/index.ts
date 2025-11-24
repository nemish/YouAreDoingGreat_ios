import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useMenuStore from "@/hooks/stores/useMenuStore";
import { useCallback, useEffect, useMemo, useState } from "react";
import { Dimensions } from "react-native";
import { Gesture } from "react-native-gesture-handler";
import { runOnJS, useSharedValue, withTiming } from "react-native-reanimated";

const height = Dimensions.get("window").height;
const hiddenPosition = height - 150;
const TOGGLE_THRESHOLD = 80;

const useHidePanelGesture = () => {
  const translateY = useSharedValue(0);
  const [isPanning, setIsPanning] = useState(false);
  const setActiveItem = useMenuStore((state) => state.setActiveItem);
  const activeItem = useMenuStore((state) => state.activeItem);

  const isInitMomentPanelShown = useMainPanelStore(
    (state) => state.isInitMomentPanelShown
  );
  const setMainPanelState = useMainPanelStore(
    (state) => state.setMainPanelState
  );
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  const togglePanel = useCallback(
    (value: boolean) => {
      setIsShown(value);
      if (value) {
        // setTimeout(() => {
        //   router.navigate("/");
        // }, 100);
      } else {
        setMainPanelState("init");
      }
    },
    [setIsShown, setActiveItem, setMainPanelState, activeItem]
  );

  const isHidden = !isInitMomentPanelShown;

  useEffect(() => {
    if (isInitMomentPanelShown) {
      translateY.value = withTiming(0, {
        duration: 300,
      });
    } else {
      translateY.value = withTiming(hiddenPosition, {
        duration: 300,
      });
    }
  }, [isInitMomentPanelShown]);

  const swipeGesture = useMemo(
    () =>
      Gesture.Pan()
        .onBegin(() => {
          if (!isPanning) {
            runOnJS(setIsPanning)(true);
          }
        })
        .onUpdate((event) => {
          if (event.translationY > 0 && !isHidden) {
            translateY.value = Math.min(event.translationY, hiddenPosition);
          }
          if (event.translationY < 0 && isHidden) {
            translateY.value = Math.min(
              hiddenPosition + event.translationY,
              hiddenPosition
            );
          }
        })
        .onEnd((event) => {
          runOnJS(setIsPanning)(false);
          if (!isHidden && event.translationY > TOGGLE_THRESHOLD) {
            translateY.value = withTiming(hiddenPosition, { duration: 300 });
            runOnJS(togglePanel)(false);
          } else if (isHidden && event.translationY < -TOGGLE_THRESHOLD + 30) {
            translateY.value = withTiming(0, { duration: 300 });
            runOnJS(togglePanel)(true);
          } else {
            translateY.value = withTiming(isHidden ? hiddenPosition : 0, {
              duration: 300,
            });
          }
        }),
    [isHidden]
  );

  return { translateY, swipeGesture, isHidden, isPanning };
};

export default useHidePanelGesture;
