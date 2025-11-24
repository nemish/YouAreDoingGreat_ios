import { useEffect } from "react";
import { Platform } from "react-native";
import Purchases, { LOG_LEVEL } from "react-native-purchases";

const useRevenueCat = () => {
  useEffect(() => {
    Purchases.setLogLevel(LOG_LEVEL.VERBOSE);
    const apiKey = process.env.EXPO_PUBLIC_REVENUECAT_API_KEY as string;

    if (Platform.OS === "ios") {
      Purchases.configure({
        apiKey,
      });
    } else if (Platform.OS === "android") {
      //    Purchases.configure({apiKey: <revenuecat_project_google_api_key>});
      //   // OR: if building for Amazon, be sure to follow the installation instructions then:
      //    Purchases.configure({ apiKey: <revenuecat_project_amazon_api_key>, useAmazon: true });
    }
  }, []);
};

export default useRevenueCat;
