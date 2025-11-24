import type { Moment } from "@/constants/types";
import { MotiView } from "moti";
import { useEffect, useState } from "react";
import { ActivityIndicator, ScrollView, Text, View } from "react-native";
import { LinearTransition } from "react-native-reanimated";
import useMomentQuery from "./hooks/useMomentQuery";

type Props = {
  item: Moment;
};

const PraiseText = ({ item }: Props) => {
  const [ready, setReady] = useState(false);
  const { data: moment, isLoading } = useMomentQuery(item.id);
  const [hasAnimated, setHasAnimated] = useState(false);

  // Trigger animation after initial render
  useEffect(() => {
    const timer = setTimeout(() => {
      setHasAnimated(true);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    const timer = setTimeout(() => {
      setReady(true);
    }, 200);
    return () => clearTimeout(timer);
  }, []);

  return (
    <MotiView layout={LinearTransition.springify()} className="overflow-hidden">
      {(!ready || isLoading) && (
        <MotiView
          from={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ type: "timing", duration: 200 }}
          className="py-2 justify-center items-center"
          style={{ minHeight: 40 }}
        >
          <ActivityIndicator size="small" color="#9ca3af" />
        </MotiView>
      )}

      {ready && !isLoading && !moment && (
        <MotiView
          from={{ opacity: 0, translateY: 10 }}
          animate={{ opacity: 1, translateY: 0 }}
          transition={{ type: "timing", duration: 300 }}
          className="py-2 justify-center items-center"
          style={{ minHeight: 50 }}
        >
          <Text className="text-gray-500 text-center">No praise yet</Text>
        </MotiView>
      )}

      {ready && !isLoading && moment && moment.praise && (
        <View className="overflow-hidden">
          <ScrollView
            className="max-h-80"
            showsVerticalScrollIndicator={false}
            contentContainerStyle={{
              flexDirection: "row",
              flexWrap: "wrap",
              gap: 8,
              paddingVertical: 8,
            }}
          >
            {moment.praise.split(" ").map((word: string, wordIndex: number) => (
              <MotiView
                key={`${word}-${wordIndex}`}
                from={{ opacity: 0, translateY: -3 }}
                animate={{ opacity: 1, translateY: 0 }}
                transition={{
                  type: "timing",
                  duration: 150,
                  delay: hasAnimated ? wordIndex * 15 : 0,
                }}
              >
                <Text
                  style={{ fontFamily: "Comfortaa" }}
                  className="text-base text-gray-700 opacity-60 text-center leading-tight"
                >
                  {word}
                </Text>
              </MotiView>
            ))}
          </ScrollView>
        </View>
      )}
    </MotiView>
  );
};

export default PraiseText;
