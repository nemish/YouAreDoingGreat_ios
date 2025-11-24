import BottomMenu from "@/components/features/HomeScreen/components/BottomMenu";
import { MotiView } from "moti";
import { View } from "react-native";

type Props = {
  isHidden: boolean;
  isPanning: boolean;
};

const HidePanelControl = ({ isHidden }: Props) => {
  return (
    <View className="w-full absolute top-0 left-0 z-10 flex items-center justify-center h-1/4">
      <MotiView
        animate={{ opacity: isHidden ? 1 : 0 }}
        transition={{
          type: "timing",
          duration: 500,
        }}
        className="absolute top-2 left-0 w-full h-24 flex z-20"
        pointerEvents={isHidden ? "auto" : "none"}
      >
        <BottomMenu />
      </MotiView>
      <View className="w-16 h-2 bg-white opacity-20 rounded-full absolute top-2"></View>
    </View>
  );
};

export default HidePanelControl;
