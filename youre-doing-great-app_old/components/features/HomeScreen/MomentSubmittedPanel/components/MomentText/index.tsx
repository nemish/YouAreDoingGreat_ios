import { MotiView } from "moti";
import { Text, View } from "react-native";

type Props = {
  text: string;
};

const MomentText = ({ text }: Props) => {
  return (
    <View className="flex flex-row flex-wrap gap-2">
      {text.split(" ").map((word, wordIndex) => (
        <MotiView
          key={`${word}-${wordIndex}`}
          from={{ opacity: 0, translateY: -10 }}
          animate={{ opacity: 1, translateY: 0 }}
          transition={{
            type: "timing",
            duration: 400,
            delay: wordIndex * Math.max(80 - wordIndex * 7, 80),
          }}
        >
          <Text
            style={{ fontFamily: "PatrickHand" }}
            className="text-3xl text-white opacity-60 text-center"
          >
            {word}
          </Text>
        </MotiView>
      ))}
    </View>
  );
};

export default MomentText;
