import CommonText from "@/components/ui/CommonText";
import FancyButton from "@/components/ui/FancyButton";
import useSubmitFeedbackMutation from "@/hooks/useSubmitFeedbackMutation";
import React, { useCallback } from "react";
import { Controller, useForm } from "react-hook-form";
import { Alert, Linking, Pressable, TextInput, View } from "react-native";

type ContactFormData = {
  title: string;
  message: string;
};

const ContactUs = React.memo(() => {
  const {
    control,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm<ContactFormData>({
    defaultValues: {
      title: "",
      message: "",
    },
  });

  const { mutateAsync: submitFeedback, isPending } =
    useSubmitFeedbackMutation();

  const onSubmit = useCallback(
    async (data: ContactFormData) => {
      try {
        await submitFeedback({
          title: data.title,
          text: data.message,
        });

        // Reset form after successful submission
        reset();

        // Show success message
        Alert.alert(
          "Message Sent!",
          "Thank you for your feedback. We'll get back to you soon!",
          [{ text: "OK" }]
        );
      } catch (error) {
        // Show error message
        Alert.alert(
          "Error",
          "Failed to send message. Please try again or contact us directly via email.",
          [{ text: "OK" }]
        );
        console.error("Failed to send message:", error);
      }
    },
    [submitFeedback, reset]
  );

  const handleEmailPress = useCallback(() => {
    Linking.openURL("mailto:info@you-are-doing-great.com");
  }, []);

  return (
    <View className="p-4">
      <CommonText className="mb-4 text-xl font-bold text-white">
        Contact Us
      </CommonText>

      <CommonText className="text-white/80 mb-6 leading-6">
        We'd love to hear from you! Whether you have feedback, suggestions, or
        need help with something, we're here to listen and help make your
        experience even better.
      </CommonText>

      <View className="flex gap-4">
        <View>
          <CommonText className="text-white font-medium mb-2">
            Subject
          </CommonText>
          <Controller
            control={control}
            name="title"
            rules={{
              required: "Subject is required",
              minLength: {
                value: 1,
                message: "Subject must be at least 1 character",
              },
              maxLength: {
                value: 200,
                message: "Subject must be less than 200 characters",
              },
            }}
            render={({ field: { onChange, onBlur, value } }) => (
              <View>
                <TextInput
                  value={value}
                  onChangeText={onChange}
                  onBlur={onBlur}
                  placeholder="What's this about?"
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  //   className="rounded-lg px-4 py-3 text-white border border-white/30"
                  className="py-3 px-4 border border-dashed border-cyan-700 rounded-xl text-white"
                />
                {errors.title && (
                  <CommonText className="text-red-400 text-sm mt-1">
                    {errors.title.message}
                  </CommonText>
                )}
              </View>
            )}
          />
        </View>

        <View>
          <CommonText className="text-white font-medium mb-2">
            Message
          </CommonText>
          <Controller
            control={control}
            name="message"
            rules={{
              required: "Message is required",
              minLength: {
                value: 1,
                message: "Message must be at least 1 character",
              },
              maxLength: {
                value: 5000,
                message: "Message must be less than 5000 characters",
              },
            }}
            render={({ field: { onChange, onBlur, value } }) => (
              <View>
                <TextInput
                  value={value}
                  onChangeText={onChange}
                  onBlur={onBlur}
                  placeholder="Tell us what's on your mind..."
                  placeholderTextColor="rgba(255, 255, 255, 0.5)"
                  multiline
                  numberOfLines={4}
                  textAlignVertical="top"
                  className="py-3 px-4 border border-dashed border-cyan-700 rounded-xl min-w-full max-w-full text-white min-h-24"
                  //   className="rounded-lg px-4 py-3 text-white border border-white/30 min-h-[100px]"
                />
                {errors.message && (
                  <CommonText className="text-red-400 text-sm mt-1">
                    {errors.message.message}
                  </CommonText>
                )}
              </View>
            )}
          />
        </View>

        <FancyButton
          text={isPending ? "Sending..." : "Send Message"}
          onPress={handleSubmit(onSubmit)}
          size="base"
          kind="oceanBlue"
          fullWidth
          isDisabled={isPending}
        />
      </View>

      <View className="mt-6 pt-4 border-t border-white/20">
        <CommonText className="text-white/70 text-center">
          Or reach us directly at:
        </CommonText>
        <Pressable onPress={handleEmailPress} className="mt-2">
          <CommonText className="text-white font-semibold text-center text-lg">
            info@you-are-doing-great.com
          </CommonText>
        </Pressable>
      </View>
    </View>
  );
});

ContactUs.displayName = "ContactUs";

export default ContactUs;
