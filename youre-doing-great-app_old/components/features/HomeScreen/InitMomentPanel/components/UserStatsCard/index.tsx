import CommonText from "@/components/ui/CommonText";
import { useUserStatsQuery } from "@/hooks/useUserStatsQuery";
import { getRandomFromArray } from "@/utils/texts";
import { MaterialIcons } from "@expo/vector-icons";
import { LinearGradient } from "expo-linear-gradient";
import { MotiView } from "moti";
import { useMemo } from "react";
import { StyleSheet, View } from "react-native";

type StatItemProps = {
  label: string;
  value: number | string;
  delay: number;
  icon: keyof typeof MaterialIcons.glyphMap;
  iconColor?: string;
};

const StatItem = ({
  label,
  value,
  delay,
  icon,
  iconColor = "rgba(255, 255, 255, 0.9)",
}: StatItemProps) => {
  const words = label.split(" ");

  return (
    <MotiView
      from={{ opacity: 0, translateY: 20 }}
      animate={{ opacity: 1, translateY: 0 }}
      transition={{
        type: "timing",
        duration: 600,
        delay,
      }}
      className="flex items-center"
    >
      <MotiView
        from={{ scale: 0 }}
        animate={{ scale: 1 }}
        transition={{
          type: "spring",
          duration: 800,
          delay: delay + 200,
        }}
        className="mb-2"
      >
        <MaterialIcons name={icon} size={24} color={iconColor} />
      </MotiView>
      <CommonText type="playfull" className="text-4xl font-bold text-white">
        {value}
      </CommonText>
      <View className="mt-1">
        {words.map((word, index) => (
          <CommonText key={index} className="text-sm text-white/70 text-center">
            {word}
          </CommonText>
        ))}
      </View>
    </MotiView>
  );
};

export const METRIC_WHISPERS = [
  `Every number here is a story you told yourself.`,
  `Tiny things. Big difference.`,
  `The fact you’re tracking this means you care.`,
  `Little moments. Real effort. Honest wins.`,
  `No one else needed to see it — just you.`,
];

const UserStatsCard = () => {
  const { data: stats, isLoading } = useUserStatsQuery();
  const whisper = useMemo(() => getRandomFromArray(METRIC_WHISPERS), []);

  if (isLoading || !stats) {
    return null;
  }

  return (
    <MotiView
      from={{ opacity: 0, scale: 0.9 }}
      animate={{ opacity: 1, scale: 1 }}
      transition={{
        type: "timing",
        duration: 800,
      }}
      className="mx-6"
    >
      <View style={styles.cardContainer}>
        <LinearGradient
          colors={["rgba(255, 255, 255, 0.15)", "rgba(255, 255, 255, 0.05)"]}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        >
          {/* Glowing border effect */}
          <View style={styles.glowBorder} />
          <MotiView
            from={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{
              type: "timing",
              duration: 800,
            }}
            className="mt-4"
          >
            <CommonText className="text-xs font-bold text-white/50 text-center">
              {whisper}
            </CommonText>
          </MotiView>

          <View className="flex-row justify-around items-center p-4">
            <StatItem
              label="Current Streak"
              value={stats.currentStreak}
              delay={100}
              icon="local-fire-department"
              iconColor="#FFA500"
            />
            <View className="w-px h-12 bg-white/20" />
            <StatItem
              label="Total Moments"
              value={stats.totalMoments}
              delay={200}
              icon="star"
              iconColor="#FFD700"
            />
            <View className="w-px h-12 bg-white/20" />
            <StatItem
              label="Longest Streak"
              value={stats.longestStreak}
              delay={300}
              icon="emoji-events"
              iconColor="#C0C0C0"
            />
          </View>
        </LinearGradient>
      </View>
    </MotiView>
  );
};

const styles = StyleSheet.create({
  cardContainer: {
    borderRadius: 24,
    overflow: "hidden",
    borderWidth: 1,
    borderColor: "rgba(255, 255, 255, 0.2)",
    shadowColor: "#000",
    shadowOffset: {
      width: 0,
      height: 4,
    },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 8,
  },
  glowBorder: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    height: 1,
    backgroundColor: "rgba(255, 255, 255, 0.5)",
  },
});

export default UserStatsCard;
