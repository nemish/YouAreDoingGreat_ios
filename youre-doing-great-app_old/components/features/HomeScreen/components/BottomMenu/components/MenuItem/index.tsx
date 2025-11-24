import Icon from "@/components/ui/LucideIcon";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import type { MenuItemName } from "@/hooks/stores/useMenuStore";
import useMenuStore from "@/hooks/stores/useMenuStore";
import { router } from "expo-router";
import { MotiView } from "moti";
import { Pressable } from "react-native";

type Props = {
  icon: any;
  itemName: MenuItemName;
};

const MenuItem = ({ icon, itemName }: Props) => {
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  const activeItem = useMenuStore((state) => state.activeItem);
  const setActiveItem = useMenuStore((state) => state.setActiveItem);

  const handlePress = () => {
    if (itemName === "new-moment") {
      setIsShown(true);
      return;
    }
    setActiveItem(itemName);
    setTimeout(() => {
      router.navigate(itemName);
    }, 10);
  };

  return (
    <Pressable
      className="h-14 w-14 flex items-center justify-center"
      onPress={handlePress}
    >
      <MotiView
        animate={{
          opacity: activeItem === itemName ? 1 : 0.5,
          translateY: activeItem === itemName ? -4 : 0,
        }}
        transition={{ type: "timing", duration: 100 }}
      >
        <Icon name={icon} size={24} color="#ffb3c6" />
      </MotiView>
    </Pressable>
  );
};

export default MenuItem;
