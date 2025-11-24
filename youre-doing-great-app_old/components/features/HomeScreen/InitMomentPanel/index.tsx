import FancyButton from "@/components/ui/FancyButton";
import { View } from "react-native";
import TitleText from "./components/TitleText";
import UserStatsCard from "./components/UserStatsCard";

type Props = {
  onPress: () => void;
};

const InitMomentPanel = ({ onPress }: Props) => {
  return (
    <View className="flex-1 flex pb-36">
      <View className="flex-1 flex items-end justify-end px-6 gap-10">
        <View className="w-full mb-10">
          <UserStatsCard />
        </View>
        <TitleText />
        <FancyButton className="mr-4" onPress={onPress} size="lg" />
      </View>
    </View>
  );
};

export default InitMomentPanel;
