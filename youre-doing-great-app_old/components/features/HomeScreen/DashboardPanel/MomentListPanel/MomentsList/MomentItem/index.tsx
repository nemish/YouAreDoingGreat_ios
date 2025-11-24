import type { Moment } from "@/constants/types";
import { MotiPressable } from "moti/interactions";
import React, { useMemo } from "react";
import { View } from "react-native";
import HighlightAnimationWrapper from "./HighlightAnimationWrapper";
import MomentItemInfo from "./MomentItemInfo";

type Props = {
  item: Moment;
  isHighlighted: boolean;
  isInitMomentPanelShown: boolean;
  onLongPress: (item: Moment) => void;
};

const MomentItem = React.memo(
  ({ item, isHighlighted, isInitMomentPanelShown, onLongPress }: Props) => {
    const shouldAnimate = !isInitMomentPanelShown && isHighlighted;

    // Memoize the animation function to prevent recreation on every render
    const longPressAnimate = useMemo(
      () =>
        ({ pressed }: { pressed: boolean }) => {
          "worklet";
          return {
            scale: pressed ? 0.95 : 1,
          };
        },
      []
    );

    return (
      <View className="flex-1 rounded-xl relative">
        <MotiPressable
          key={item.id}
          from={{ scale: 1 }}
          animate={longPressAnimate}
          onLongPress={() => onLongPress(item)}
          transition={{
            type: "timing",
            duration: 500,
          }}
        >
          <HighlightAnimationWrapper shouldAnimate={shouldAnimate}>
            <MomentItemInfo item={item} />
          </HighlightAnimationWrapper>
        </MotiPressable>
      </View>
    );
  },
  (prevProps, nextProps) => {
    // Only re-render if relevant props changed
    return (
      prevProps.item.id === nextProps.item.id &&
      prevProps.isHighlighted === nextProps.isHighlighted &&
      prevProps.isInitMomentPanelShown === nextProps.isInitMomentPanelShown &&
      prevProps.onLongPress === nextProps.onLongPress
    );
  }
);

MomentItem.displayName = "MomentItem";

export default MomentItem;
