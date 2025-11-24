import CommonText from "@/components/ui/CommonText";
import { View } from "react-native";

type Props = {
  text: string;
};

// Predefined color palette for tags
const TAG_COLORS = [
  "#ef4444", // red
  "#f59e0b", // amber
  "#10b981", // emerald
  "#3b82f6", // blue
  "#8b5cf6", // violet
  "#ec4899", // pink
  "#06b6d4", // cyan
  "#84cc16", // lime
  "#f97316", // orange
  "#6366f1", // indigo
];

// Simple hash function to consistently map tag names to colors
const getTagColor = (tag: string): string => {
  let hash = 0;
  for (let i = 0; i < tag.length; i++) {
    hash = tag.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % TAG_COLORS.length;
  return TAG_COLORS[index];
};

const Tag = ({ text }: Props) => {
  const backgroundColor = getTagColor(text);
  const displayText = text.split("_").join(" ");

  return (
    <View
      className="px-3 py-1.5 rounded-full"
      style={{ backgroundColor }}
    >
      <CommonText className="text-xs font-medium text-white whitespace-nowrap">
        #{displayText}
      </CommonText>
    </View>
  );
};

export default Tag;
