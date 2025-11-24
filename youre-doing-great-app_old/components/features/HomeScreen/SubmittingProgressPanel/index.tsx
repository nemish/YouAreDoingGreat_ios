import { Text, View } from "react-native";
import useLoadingText from "./hooks/useLoadingText";

const SubmittingProgressPanel = () => {
  const loadingText = useLoadingText();
  return (
    <View className="flex-1 flex items-center justify-center">
      <Text
        style={{ fontFamily: "PatrickHand" }}
        className="text-2xl font-bold"
      >
        {loadingText}
      </Text>
    </View>
  );
};

export default SubmittingProgressPanel;
