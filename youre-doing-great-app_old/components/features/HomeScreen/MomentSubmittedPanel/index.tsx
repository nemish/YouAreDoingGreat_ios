import FancyButton from "@/components/ui/FancyButton";
import { useQueryClient } from "@tanstack/react-query";
import { View } from "react-native";
import MomentText from "./components/MomentText";

type Props = {
  data: any;
  setIsPressed: (isPressed: boolean) => void;
  setIsShowForm: (isShowForm: boolean) => void;
};

const MomentSubmittedPanel = ({ data, setIsPressed, setIsShowForm }: Props) => {
  const client = useQueryClient();
  return (
    <View className="flex-1 flex items-center justify-center px-6 gap-10">
      <MomentText text={data.message || "No moment yet"} />
      <View className="flex flex-row items-center justify-center gap-4">
        <FancyButton
          onPress={() => {
            setIsPressed(false);
            setIsShowForm(false);
            client.setQueryData(["latestMoment"], null);
            client.invalidateQueries({ queryKey: ["latestMoment"] });
          }}
          kind="friendlyFire"
          size="sm"
          text="That's it"
        />
        <FancyButton
          onPress={() => {
            console.log("submit another moment");
          }}
          size="sm"
          text="Explore"
        />
      </View>
    </View>
  );
};

export default MomentSubmittedPanel;
