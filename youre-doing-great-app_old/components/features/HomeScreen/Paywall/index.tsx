import LucideIcon from "@/components/ui/LucideIcon";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import { useRestorePurchases } from "@/hooks/useRestorePurchases";
import classnames from "classnames";
import { LinearGradient } from "expo-linear-gradient";
import { MotiView } from "moti";
import { Image, Pressable, ScrollView, Text, View } from "react-native";
import ChoosePlanForm from "./components/ChoosePlanForm";

const PHRASES = [
  {
    text: "The small things matter. That's where life hides.",
    author: "Jon Kabat-Zinn",
  },
  {
    text: "The day you plant the seed is not the day you eat the fruit.",
    author: "Fabienne Fredrickson",
  },
  {
    text: "It always seems impossible until it is done.",
    author: "Nelson Mandela",
  },
  {
    text: "There is no such thing as a small act of kindness.",
    author: "Aesop",
  },
  {
    text: "Do what you can, with what you have, where you are.",
    author: "Theodore Roosevelt",
  },
  {
    text: "A journey of a thousand miles begins with a single step.",
    author: "Lao Tzu",
  },
];

const randomPhrase = PHRASES[Math.floor(Math.random() * PHRASES.length)];

const img = require("@/assets/images/laurel-right.png");

const Paywall = () => {
  const restorePurchasesMutation = useRestorePurchases();
  const extraData = useMainPanelStore((state) => state.extraData);

  const handleRestorePurchases = () => {
    restorePurchasesMutation.mutate();
  };

  return (
    <View className="flex-1">
      <LinearGradient
        colors={["rgba(0,0,0,0.9)", "rgba(0,0,0,0.9)", "transparent"]}
        locations={[0, 0.4, 1]}
        start={{ x: 0.5, y: 1 }}
        end={{ x: 0.5, y: 0.1 }}
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
        }}
      ></LinearGradient>
      <ScrollView
        className="flex-1"
        showsVerticalScrollIndicator={false}
        contentContainerStyle={{ flexGrow: 1 }}
      >
        {extraData?.isDailyLimitReached && (
          <MotiView
            className="m-8 p-4 bg-blue-400 rounded-lg"
            from={{
              opacity: 0,
              scale: 0.8,
              translateY: -20,
            }}
            animate={{
              opacity: 1,
              scale: 1,
              translateY: 0,
            }}
            transition={{
              type: "spring",
              damping: 15,
              stiffness: 150,
              delay: 100,
            }}
          >
            <View className="flex-row items-center justify-center gap-3">
              <MotiView
                from={{
                  scale: 0,
                  rotate: "0deg",
                }}
                animate={{
                  scale: 1,
                  rotate: "0deg",
                }}
                transition={{
                  type: "spring",
                  damping: 12,
                  stiffness: 200,
                  delay: 300,
                }}
              >
                <LucideIcon name="alert-triangle" size={20} color="#dbeafe" />
              </MotiView>
              <Text
                style={{ fontFamily: "Comfortaa" }}
                className="text-blue-50 font-bold text-center flex-1"
              >
                Daily limit reached. Go premium to continue without
                interruptions.
              </Text>
            </View>
          </MotiView>
        )}
        <View className="">
          <MotiView
            className={classnames(
              "px-6",
              extraData?.isDailyLimitReached ? "py-8" : "py-20"
            )}
            from={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{
              type: "timing",
              duration: 500,
              delay: 200,
            }}
          >
            <Text
              // style={{ fontFamily: "PatrickHand" }}
              style={{ fontFamily: "Comfortaa" }}
              className="text-3xl text-blue-200 font-bold text-center"
            >
              You've been doing the hard part already
            </Text>
            <Text
              // style={{ fontFamily: "PatrickHand" }}
              style={{ fontFamily: "Comfortaa" }}
              className="text-white font-bold opacity-50 text-center mt-8"
            >
              This is just to keep the light on.
            </Text>
          </MotiView>
          <MotiView
            className="px-6"
            from={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{
              type: "timing",
              duration: 500,
              delay: 1000,
            }}
          >
            <View className="flex-row items-center justify-center w-full">
              <Image
                source={img}
                className="w-20 h-20"
                style={{ transform: [{ scaleX: -1 }] }}
              />
              <View className="w-2/3">
                <Text
                  style={{ fontFamily: "Comfortaa" }}
                  className="text text-blue-100 font-bold text-center"
                >
                  {randomPhrase.text}
                </Text>
                <Text
                  style={{ fontFamily: "Comfortaa" }}
                  className="text-sm text-blue-100 opacity-90 font-thin text-center mt-4"
                >
                  {randomPhrase.author}
                </Text>
              </View>
              <Image source={img} className="w-20 h-20" />
            </View>
          </MotiView>
        </View>
        <MotiView
          className="flex items-end justify-end pb-20 gap-6"
          from={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{
            type: "timing",
            duration: 500,
            delay: 1500,
          }}
        >
          <View className="px-4 w-full">
            <Text
              style={{ fontFamily: "Comfortaa" }}
              className="text-blue-100 text-center mt-4 text-lg font-bold"
            >
              Unlock up to 50 praises per day
            </Text>
          </View>
          <ChoosePlanForm />
          <View className="px-4 w-full gap-4">
            <View className="flex-row items-center justify-around w-full opacity-50">
              <Text style={{ fontFamily: "Comfortaa" }} className="text-white">
                Terms of service
              </Text>
              <Text style={{ fontFamily: "Comfortaa" }} className="text-white">
                Privacy policy
              </Text>
            </View>
            <Pressable
              onPress={handleRestorePurchases}
              disabled={restorePurchasesMutation.isPending}
            >
              <Text
                style={{ fontFamily: "Comfortaa" }}
                className={`text-white text-center opacity-50 ${
                  restorePurchasesMutation.isPending && "opacity-30"
                }`}
              >
                {restorePurchasesMutation.isPending
                  ? "Restoring..."
                  : "Restore purchases"}
              </Text>
            </Pressable>
          </View>
        </MotiView>
      </ScrollView>
    </View>
  );
};

export default Paywall;
