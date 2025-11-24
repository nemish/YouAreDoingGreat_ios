import { MotiView } from "moti";
import { useMemo } from "react";
import { StyleSheet, Text, View } from "react-native";

const TITLE_PHRASES = [
  "Most of life is just doing stuff you don't want to do, a little earlier than you were ready.",
  "You don't need to fix everything. Just... clean one dish. Then see what happens.",
  "You're not lazy. You're just overwhelmed and have wifi.",
  "Some days you win. Some days you brush your teeth and that's it.",
  "The hardest thing in the world is starting. And you're alive, so technically, you started.",
  "The bar for success is lower than you think. It's basically on the floor.",
  "You don't need to be amazing. You need to be slightly less catastrophic than yesterday.",
  'Life is just a series of "ugh, fine" moments strung together.',
  "Doing something badly still counts as doing it.",
  "You're not supposed to feel motivated. That's a lie invented by fitness instructors.",
  "Everyone else is also struggling. they're just better at filters.",
  "You can move through a day without yelling at yourself. Try it. It's weird.",
  "Someone out there thinks you're doing great. They're wrong. But it's nice.",
  "Most things you're worried about don't matter. The rest will happen anyway.",
  "You don't have to win. Just... don't lose to the couch again.",
  "Your brain is a jerk. Don't let it be in charge.",
  "Action beats thinking. Almost every time.",
  "Everyone's faking it. Some people are just wearing pants.",
  "The first step is usually something dumb. Take it anyway.",
  "If you showed up, you're already halfway to something. Even if it's a nap.",
];

const TitleText = () => {
  const text = useMemo(() => {
    return TITLE_PHRASES[Math.floor(Math.random() * TITLE_PHRASES.length)];
  }, []);

  return (
    <View className="flex flex-row flex-wrap gap-3">
      {text.split(" ").map((word: string, wordIndex: number) => (
        <View key={wordIndex}>
          <View className="flex-row">
            {word.split("").map((char: string, index: number) => (
              <MotiView
                key={`${char}-${index}`}
                from={{ opacity: 0.3, scale: 1 }}
                animate={{ opacity: 0.8, scale: 1.2 }}
                transition={{
                  loop: true,
                  type: "timing",
                  duration: 3000,
                  delay: wordIndex * 400 + index * 50,
                  repeatReverse: true,
                }}
              >
                <Text
                  style={{ fontFamily: "PatrickHand" }}
                  //   style={{ fontFamily: "Comfortaa" }}
                  className="text-5xl text-white opacity-60 font-bold"
                >
                  {char}
                </Text>
              </MotiView>
            ))}
          </View>
        </View>
      ))}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    opacity: 0.8,
    marginVertical: 32,
    paddingHorizontal: 16,
  },
});

export default TitleText;
