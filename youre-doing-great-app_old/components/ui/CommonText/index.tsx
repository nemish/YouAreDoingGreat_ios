import { StyleSheet, Text } from "react-native";

type Props = {
  children: React.ReactNode;
  type?: "default" | "playfull";
  className?: string;
  numberOfLines?: number;
};

const CommonText = ({
  children,
  type = "default",
  className,
  numberOfLines,
}: Props) => {
  // Fallback to default style if type is somehow invalid
  const textStyle = styles[type] || styles.default;

  return (
    <Text style={textStyle} className={className} numberOfLines={numberOfLines}>
      {children}
    </Text>
  );
};

const styles = StyleSheet.create({
  default: {
    fontFamily: "Comfortaa",
  },
  playfull: {
    fontFamily: "PatrickHand",
  },
});

export default CommonText;
