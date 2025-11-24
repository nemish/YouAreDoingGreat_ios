import { View } from "react-native";
import CommonText from "@/components/ui/CommonText";
import { useEffect, useState } from "react";
import NetInfo from "@react-native-community/netinfo";

/**
 * OfflineBanner Component
 * Shows a banner at the top when the device is offline
 */
export const OfflineBanner = () => {
  const [isOffline, setIsOffline] = useState(false);

  useEffect(() => {
    // Subscribe to network state changes
    const unsubscribe = NetInfo.addEventListener((state) => {
      setIsOffline(!state.isConnected);
    });

    // Check initial state
    NetInfo.fetch().then((state) => {
      setIsOffline(!state.isConnected);
    });

    return () => unsubscribe();
  }, []);

  if (!isOffline) {
    return null;
  }

  return (
    <View className="bg-orange-600 py-2 px-4">
      <CommonText className="text-white text-center text-sm font-semibold">
        📵 No Internet Connection
      </CommonText>
    </View>
  );
};

export default OfflineBanner;
