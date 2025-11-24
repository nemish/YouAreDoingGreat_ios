import { View } from "react-native";
import MenuItem from "./components/MenuItem";

const BottomMenu = () => {
  return (
    <View className="flex-1 flex items-center justify-center flex-row gap-4">
      <MenuItem icon="pencil" itemName="new-moment" />
      <MenuItem icon="layout-dashboard" itemName="/" />
      <MenuItem icon="route" itemName="/timeline" />
      {/* <MenuItem icon="book-open" itemName="materials" /> */}
      <MenuItem icon="settings" itemName="/profile" />
    </View>
  );
};

export default BottomMenu;
