import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useModalStore from "@/hooks/stores/useModalStore";
import { BlurView } from "expo-blur";
import { AnimatePresence, MotiView } from "moti";
import React from "react";
import { Pressable, View } from "react-native";
import MomentModal from "./MomentModal";

const Modals = () => {
  const modalType = useModalStore((state) => state.modalType);
  const payload = useModalStore((state) => state.payload);
  const closeModal = useModalStore((state) => state.closeModal);
  const setIsShown = useMainPanelStore((state) => state.setIsShown);

  return (
    <AnimatePresence>
      {modalType === "moment" && payload && (
        <MotiView
          from={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{
            type: "timing",
            duration: 200,
          }}
          className="absolute top-0 left-0 right-0 bottom-0 flex items-center justify-center z-50"
        >
          {/* Background overlay */}
          <View className="absolute top-0 left-0 right-0 bottom-0 bg-gray-800/80" />
          <BlurView
            intensity={30}
            tint="dark"
            style={{
              position: "absolute",
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
            }}
          />
          <Pressable
            className="absolute top-0 left-0 right-0 bottom-0"
            onPress={() => {
              closeModal();
              setIsShown(false);
            }}
          />

          {/* Modal content */}
          <MomentModal item={payload} />
        </MotiView>
      )}
    </AnimatePresence>
  );
};

export default Modals;
