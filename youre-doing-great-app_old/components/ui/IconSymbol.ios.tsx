import Icon from "@/components/ui/LucideIcon";
import type { SymbolWeight } from "expo-symbols";
import type { StyleProp, ViewStyle } from "react-native";

export function IconSymbol({
  name,
  size = 24,
  color,
  style,
  weight = "regular",
}: {
  // name: SymbolViewProps['name'];
  name: any;
  size?: number;
  color: string;
  style?: StyleProp<ViewStyle>;
  weight?: SymbolWeight;
}) {
  return <Icon name={name} size={size} color={color} />;
  // return (
  //   <SymbolView
  //     weight={weight}
  //     tintColor={color}
  //     resizeMode="scaleAspectFit"
  //     name={name}
  //     style={[
  //       {
  //         width: size,
  //         height: size,
  //       },
  //       style,
  //     ]}
  //   />
  // );
}
