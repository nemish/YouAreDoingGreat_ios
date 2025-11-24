import CommonText from "@/components/ui/CommonText";
import LucideIcon from "@/components/ui/LucideIcon";
import type { Moment } from "@/constants/types";
import useTimeOfDayElements from "@/hooks/useTimeOfDayElements";
import { MotiView } from "moti";
import { View } from "react-native";
import ActionButtons from "./ActionButtons";
import PraiseText from "./PraiseText";

type Props = {
  item: Moment;
};

const MomentModal = ({ item }: Props) => {
  const { styles, icon, formattedDate } = useTimeOfDayElements(item);

  return (
    <MotiView
      from={{ scale: 0.9, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      exit={{ scale: 0.9, opacity: 0 }}
      transition={{
        type: "spring",
        damping: 25,
        stiffness: 250,
        mass: 0.8,
      }}
      className="w-11/12 max-w-md mx-4 flex"
    >
      {/* Moment Card */}
      <View
        className="rounded-2xl bg-vitality-50 shadow-2xl mb-4 overflow-hidden"
        style={styles.borderStyle}
      >
        <View className="flex-row">
          {/* Main content area - 80% width */}
          <View className="flex-1 justify-between">
            <View className="p-6">
              <CommonText className="text-lg leading-6 font-medium text-gray-800 mb-4">
                {item.text}
              </CommonText>
              <PraiseText item={item} />
            </View>

            {/* Tags Section */}
            {item.tags && item.tags.length > 0 && (
              <View className="px-6 pb-3">
                <View className="flex-row flex-wrap gap-2">
                  {item.tags.map((tag, index) => (
                    <MotiView
                      key={`${tag}-${index}`}
                      from={{ opacity: 0 }}
                      animate={{ opacity: 1 }}
                      transition={{
                        type: "timing",
                        duration: 300,
                        delay: 1000 + index * 200,
                      }}
                      className="px-3 py-1.5 rounded-full"
                      style={styles.backgroundStyle}
                    >
                      <CommonText className="text-xs font-medium text-white whitespace-nowrap">
                        #{tag?.split("_").join(" ")}
                      </CommonText>
                    </MotiView>
                  ))}
                </View>
              </View>
            )}

            {/* Date at bottom */}
            <View
              className="px-4 py-2 rounded-tr-xl self-start opacity-70"
              style={styles.backgroundStyle}
            >
              <CommonText className="text-sm font-normal text-ocean-100">
                {formattedDate.date}
              </CommonText>
            </View>
          </View>

          <View className="w-3 h-full flex" style={styles.backgroundStyle}>
            <View className="flex-1 rounded-r-2xl bg-vitality-50" />
          </View>

          {/* Right accent area - 20% width */}
          <View
            className="w-1/5 items-center justify-center py-4"
            style={styles.backgroundStyle}
          >
            <LucideIcon name={icon} size={28} color="white" />
            <View className="items-center mt-2">
              <CommonText className="text-sm text-white font-normal">
                {formattedDate.time}
              </CommonText>
              <CommonText className="text-sm text-white font-normal">
                {formattedDate.ampm}
              </CommonText>
            </View>
          </View>
        </View>
      </View>
      <ActionButtons item={item} />
    </MotiView>
  );
};
export default MomentModal;
