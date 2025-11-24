import { RawThemedText } from "@/components/RawThemedText";
import { MotiView } from "moti";
import { Dimensions, StyleSheet } from "react-native";

const { height } = Dimensions.get("window");

const BOTTOM_PHRASES = [
  "You don't have to do everything. Just one thing is enough.",
  "If you feel ready — start small. If not, just breathe.",
  "You're allowed to rest. You're also allowed to try.",
  "The day doesn't need to be big. Just honest.",
  "You can take a step. Or you can sit and decide.",
  "You don't need to push. But you can lean forward a little.",
  "Tiny effort still means you showed up.",
  "If you do nothing today — that's okay. If you do one thing — that's magic.",
  "Progress doesn't always look like motion.",
  "It's fine to pause. But it's also fine to gently begin.",
  "Rest if you need. Move if you want.",
  "You're not lazy. You're listening to yourself.",
  "This isn't about pressure. It's about noticing what feels right.",
  "Some days you try. Some days you survive. Both matter.",
  "You can be still. You can also take a breath and begin again.",
];

const BottomExpandedPanel = () => {
  return (
    <MotiView
      style={[styles.bottomPanelContainer]}
      from={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      transition={{
        type: "timing",
        duration: 500,
      }}
      exit={{ opacity: 0 }}
      exitTransition={{
        type: "timing",
        duration: 200,
      }}
      className="p-12"
    >
      <RawThemedText className="text-2xl text-center">
        {BOTTOM_PHRASES[Math.floor(Math.random() * BOTTOM_PHRASES.length)]}
      </RawThemedText>
      <MotiView
        className="mt-2"
        from={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{
          delay: 500,
          type: "timing",
          duration: 500,
        }}
      >
        <RawThemedText className="text-lg text-center font-light">
          You can come back whenever it feels right.
        </RawThemedText>
      </MotiView>
    </MotiView>
  );
};

const styles = StyleSheet.create({
  bottomPanelContainer: {
    position: "absolute",
    paddingTop: 50,
    top: height * 0.75,
    height: height * 0.25,
    width: "100%",
    display: "flex",
    justifyContent: "flex-start",
    alignItems: "center",
  },
});

export default BottomExpandedPanel;
