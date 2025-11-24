import { MotiView } from "moti";
import { useCallback, useState } from "react";
import { KeyboardAvoidingView, Platform, ScrollView } from "react-native";
import QuickReaction from "./components/QuickReaction";
import SubmitMomentForm from "./components/SubmitMomentForm";

const SubmitMomentPanel = () => {
  const [_, setIsKeyboardOpen] = useState(false);

  const handleKeyboardChange = useCallback(
    (open: boolean) => setIsKeyboardOpen(open),
    []
  );
  return (
    <KeyboardAvoidingView
      behavior={Platform.OS === "ios" ? "padding" : "height"}
      keyboardVerticalOffset={-64}
    >
      <ScrollView
        keyboardShouldPersistTaps="handled"
        contentContainerStyle={{
          flexGrow: 1,
          justifyContent: "center",
        }}
      >
        <MotiView
          className="w-full px-8 flex-1 justify-end items-start"
          from={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          transition={{
            delay: 300,
            type: "timing",
            duration: 500,
          }}
        >
          <QuickReaction />
        </MotiView>
        <MotiView
          className="pb-36 mt-10"
          from={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{
            type: "timing",
            duration: 500,
            delay: 500,
          }}
        >
          <SubmitMomentForm onKeyboardChange={handleKeyboardChange} />
        </MotiView>
      </ScrollView>
    </KeyboardAvoidingView>
  );
};

export default SubmitMomentPanel;
