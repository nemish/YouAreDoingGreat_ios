import CommonText from "@/components/ui/CommonText";
import { openBrowserAsync } from "expo-web-browser";
import { useCallback } from "react";
import { Alert, Pressable } from "react-native";

type Props = {
  url: string;
  text: string;
  description: string;
};

const LinkWithDescription = ({ url, text, description }: Props) => {
  const handleOpenURL = useCallback(async (url: string) => {
    try {
      await openBrowserAsync(url);
    } catch (error) {
      console.error("Failed to open URL:", error);
      Alert.alert("Error", "Failed to open link");
    }
  }, []);

  const handleClick = useCallback(() => {
    handleOpenURL(url);
  }, [handleOpenURL]);

  return (
    <Pressable onPress={handleClick} className="py-3 border-b border-white/20">
      <CommonText className="text-white font-medium">{text}</CommonText>
      <CommonText className="text-white/60 text-sm">{description}</CommonText>
    </Pressable>
  );
};

export default LinkWithDescription;
