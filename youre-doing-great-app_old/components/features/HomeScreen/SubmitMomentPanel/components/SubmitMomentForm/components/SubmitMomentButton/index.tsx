import FancyButton from "@/components/ui/FancyButton";
import { Keyboard } from "react-native";
import useLoadingText from "./hooks/useLoadingText";
import useSubmitMomentMutation from "./hooks/useSubmitMomentMutation";

type Props = {
  isSubmitting: boolean;
  handleSubmit: any;
  isSubmitted: boolean;
  isTextFilled: boolean;
};

const SubmitMomentButton = ({
  isSubmitting,
  handleSubmit,
  isSubmitted,
  isTextFilled,
}: Props) => {
  const loadingText = useLoadingText({ isSubmitting });

  const { mutateAsync } = useSubmitMomentMutation();
  const onSubmit = async (data: any) => {
    Keyboard.dismiss();
    await mutateAsync({
      text: data.momentText || null,
      timeAgoSeconds: data.timeAgoSeconds,
    });
  };
  return (
    <FancyButton
      isDisabled={isSubmitting}
      kind={isSubmitting ? "strawberry" : "default"}
      onPress={handleSubmit(onSubmit)}
      text={
        isSubmitted
          ? "Done"
          : isSubmitting
          ? loadingText
          : isTextFilled
          ? "That's it"
          : "Keep it secret"
      }
      size="lg"
    />
  );
};

export default SubmitMomentButton;
