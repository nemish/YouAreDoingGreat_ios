import { Text, type TextProps } from "react-native";

import { useThemeColor } from "@/hooks/useThemeColor";

export type RawThemedTextProps = TextProps & {
  lightColor?: string;
  darkColor?: string;
  fontFamily?: string;
};

export function RawThemedText({
  style,
  lightColor,
  darkColor,
  fontFamily,
  ...rest
}: RawThemedTextProps) {
  const color = useThemeColor({ light: lightColor, dark: darkColor }, "text");
  return (
    <Text
      // style={[{ color }, style, { fontFamily: fontFamily || "Inter" }]}
      style={[{ color }, style, { fontFamily: fontFamily || "Comfortaa" }]}
      {...rest}
    />
  );
}
