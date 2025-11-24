import { Dimensions } from "react-native";
import Rive from "rive-react-native";

// const animation = require("@/assets/animations/rive/breathing_animation.riv");
const { width, height } = Dimensions.get("window");

const RiveHandler = () => {
  return (
    <Rive
      // url={animation}
      url="https://cdn.rive.app/animations/vehicles.riv"
      artboardName="Breathing"
      stateMachineName="Breathing"
      style={{ width, height }}
    />
  );
};

export default RiveHandler;
