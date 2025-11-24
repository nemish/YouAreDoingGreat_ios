import { Text, View } from "react-native";
import useEmptyMomentsTexts from "./hooks/useEmptyMomentsTexts";

const EmptyMoments = () => {
  const { title, description } = useEmptyMomentsTexts();
  return (
    <View className="flex-1 flex items-center justify-center p-10 gap-8">
      <Text
        style={{ fontFamily: "Comfortaa" }}
        className="text-white text-2xl font-bold text-center"
      >
        {title}
      </Text>
      <Text
        style={{ fontFamily: "Comfortaa" }}
        className="text-white text-lg text-center"
      >
        {description}
      </Text>
    </View>
  );
};
export default EmptyMoments;
