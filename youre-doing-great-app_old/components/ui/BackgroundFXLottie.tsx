import LottieView from "lottie-react-native";
import { Dimensions, StyleSheet, View } from "react-native";

const { width, height } = Dimensions.get("window");

// const animation = require("@/assets/animations/animation-bg-1.json");
// const animation = require("@/assets/animations/animation-bg-8.json");
const animation = require("@/assets/animations/animation-bg-9.json");
// const animation = require("@/assets/animations/animation-bg-6.json");

const BackgroundFXLottie = () => {
  return (
    <View style={styles.container}>
      <LottieView
        source={animation}
        autoPlay
        loop
        speed={0.5}
        resizeMode="cover"
        style={styles.lottie}
      />
      <View style={styles.overlay} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    ...StyleSheet.absoluteFillObject,
    width: width,
    height: height,
    overflow: "hidden",
    // opacity: 0.5,
  },
  lottie: {
    position: "absolute",
    // width: width * 1.4,
    // height: height * 1.4,
    width: width,
    height: height,
    left: 0,
    bottom: 0,
  },
  overlay: {
    ...StyleSheet.absoluteFillObject,
    backgroundColor: "rgba(18, 20, 24, 0.5)",
  },
});

export default BackgroundFXLottie;
