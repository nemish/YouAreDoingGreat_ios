import CommonText from "@/components/ui/CommonText";
import Icon from "@/components/ui/LucideIcon";
import type { Moment } from "@/constants/types";
import useTimeOfDayElements from "@/hooks/useTimeOfDayElements";
import React from "react";
import { View } from "react-native";

type Props = {
  item: Moment;
};

const MomentItemInfo = React.memo(({ item }: Props) => {
  const { styles, icon, formattedDate } = useTimeOfDayElements(item);
  return (
    <View
      className="rounded-xl overflow-hidden"
      style={[styles.borderStyle, styles.backgroundStyle]}
    >
      <View className="flex-row">
        <View className="flex-1 justify-between rounded-r-xl bg-vitality-50 relative">
          <View className="p-3 mb-4">
            <CommonText
              className="leading-5 font-medium text-gray-800"
              numberOfLines={3}
            >
              {item.text}
            </CommonText>
          </View>

          {/* Date at bottom */}
          <View
            className="absolute bottom-0 left-0 px-3 py-1 rounded-tr-lg self-start opacity-70"
            style={styles.backgroundStyle}
          >
            <CommonText className="text-xs font-normal text-ocean-100">
              {formattedDate.date}
            </CommonText>
          </View>
        </View>

        <View
          className="w-1/5 items-center justify-center py-2 relative"
          style={styles.backgroundStyle}
        >
          <Icon name={icon} size={20} color="white" />
          <View className="items-center mt-1">
            <CommonText className="text-xs text-white font-normal">
              {formattedDate.time}
            </CommonText>
            <CommonText className="text-xs text-white font-normal">
              {formattedDate.ampm}
            </CommonText>
          </View>

          {/* Favorite Button */}
          {item.isFavorite && (
            <View className="absolute bottom-1 left-[-24px]">
              <Icon name="heart" size={16} color="#f87171" />
            </View>
          )}
        </View>
      </View>
    </View>
  );
});

export default MomentItemInfo;
