import CommonText from "@/components/ui/CommonText";
import Tag from "@/components/ui/Tag";
import type { DaySummary, TimeOfDay } from "@/constants/types";
import { CloudSun, Moon, Sun, Sunrise, Sunset } from "lucide-react-native";
import { MotiView } from "moti";
import { View } from "react-native";

const timeOfDayIcons: Record<TimeOfDay, React.ComponentType<any>> = {
  sunrise: Sunrise,
  "cloud-sun": CloudSun,
  "sun-medium": Sun,
  sunset: Sunset,
  moon: Moon,
};

type Props = {
  item: DaySummary & { isToday?: boolean };
  index: number;
};

const TimelineItem = ({ item, index }: Props) => {
  const date = new Date(item.date);
  const day = date.getDate();
  const month = date.toLocaleDateString("en-US", { month: "short" });

  // Special rendering for "today" marker
  if (item.isToday) {
    return (
      <MotiView
        from={{ opacity: 0, translateY: 20 }}
        animate={{ opacity: 1, translateY: 0 }}
        transition={{
          type: "timing",
          duration: 400,
          delay: index * 50,
        }}
        className="flex-row"
      >
        {/* Left Column - Date */}
        <View className="w-16 items-center pt-1 pb-6">
          <CommonText className="text-2xl font-bold text-white">
            {day}
          </CommonText>
          <CommonText className="text-xs text-white/60 uppercase">
            {month}
          </CommonText>
        </View>

        {/* Timeline connector with pulsing dot */}
        <View className="w-8 items-center">
          <View className="w-0.5 h-3 bg-white/20" />
          <MotiView
            from={{ scale: 1, opacity: 0.8 }}
            animate={{ scale: 1.4, opacity: 1 }}
            transition={{
              type: "timing",
              duration: 1000,
              loop: true,
              repeatReverse: true,
            }}
            className="w-3 h-3 rounded-full bg-blue-400"
          />
          <View className="w-0.5 flex-1 bg-white/20" />
        </View>

        {/* Right Column - Today marker */}
        <View className="flex-1 pb-6">
          <View className="bg-blue-500/20 rounded-2xl p-4 backdrop-blur border border-blue-400/40">
            <CommonText className="text-base text-blue-300 font-bold">
              You are here
            </CommonText>
          </View>
        </View>
      </MotiView>
    );
  }

  return (
    <MotiView
      from={{ opacity: 0, translateY: 20 }}
      animate={{ opacity: 1, translateY: 0 }}
      transition={{
        type: "timing",
        duration: 400,
        delay: index * 50,
      }}
      className="flex-row"
    >
      {/* Left Column - Date */}
      <View className="w-16 items-center pt-1 pb-6">
        <CommonText className="text-2xl font-bold text-white">{day}</CommonText>
        <CommonText className="text-xs text-white/60 uppercase">
          {month}
        </CommonText>
      </View>

      {/* Timeline connector */}
      <View className="w-8 items-center">
        <View className="w-0.5 h-3 bg-white/20" />
        <View className="w-3 h-3 rounded-full bg-white/80" />
        <View className="w-0.5 flex-1 bg-white/20" />
      </View>

      {/* Right Column - Content */}
      <View className="flex-1 pb-6">
        <View className="bg-white/10 rounded-2xl p-4 backdrop-blur">
          {/* Header with moments count and times of day */}
          <View className="flex-row items-center justify-between">
            {/* Moments count badge */}
            {item.momentsCount > 0 && (
              <View className="flex-row items-center bg-white/15 rounded-full px-3 py-1">
                <CommonText className="text-xs text-white/90 font-semibold">
                  {item.momentsCount}{" "}
                  {item.momentsCount === 1 ? "moment" : "moments"}
                </CommonText>
              </View>
            )}

            {/* Times of day icons */}
            {item.timesOfDay && item.timesOfDay.length > 0 && (
              <View className="flex-row items-center gap-1.5">
                {item.timesOfDay.map((timeOfDay, idx) => {
                  const IconComponent = timeOfDayIcons[timeOfDay];
                  return (
                    <View key={`${timeOfDay}-${idx}`} className="opacity-70">
                      <IconComponent size={16} color="#ffffff" />
                    </View>
                  );
                })}
              </View>
            )}
          </View>

          {item.text && (
            <CommonText className="text-base text-white mb-3 leading-6 mt-3">
              {item.text}
            </CommonText>
          )}

          {item.tags && item.tags.length > 0 && (
            <View className="flex-row flex-wrap gap-2">
              {item.tags.map((tag, tagIndex) => (
                <Tag key={`${tag}-${tagIndex}`} text={tag} />
              ))}
            </View>
          )}

          {!item.text && (
            <CommonText className="text-sm text-white/40 italic">
              No moments for this day
            </CommonText>
          )}
        </View>
      </View>
    </MotiView>
  );
};

export default TimelineItem;
