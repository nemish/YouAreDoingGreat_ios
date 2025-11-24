import classnames from "classnames";
import React from "react";
import { Controller, FormProvider, useForm } from "react-hook-form";
import { TextInput, View } from "react-native";
import SubmitMomentButton from "./components/SubmitMomentButton";
import usePlaceholder from "./hooks/usePlaceholder";
import { TimeAgoSelector } from "./components/TimeAgoSelector";

type Props = {
  onKeyboardChange?: (isOpen: boolean) => void;
};

const SubmitEntryForm = ({ onKeyboardChange }: Props) => {
  const placeholder = usePlaceholder();
  const methods = useForm();
  const {
    control,
    handleSubmit,
    watch,
    setValue,
    formState: { isSubmitting, isSubmitted },
  } = methods;

  const momentText = watch("momentText", "");
  const isTextFilled = momentText && momentText.trim().length > 2;

  return (
    <FormProvider {...methods}>
      <View className="px-6 gap-6">
        <Controller
          control={control}
          render={({ field: { onChange, onBlur, value } }) => (
            <TextInput
              multiline
              maxLength={96}
              numberOfLines={3}
              placeholder={placeholder}
              textAlignVertical="top"
              placeholderTextColor="rgba(187, 187, 187, 0.5)"
              style={{
                fontFamily: "Comfortaa",
              }}
              className={classnames(
                "py-6 px-6 border-2 border-dashed border-cyan-700 rounded-xl text-2xl min-w-full max-w-full text-white min-h-32",
                isSubmitting && "opacity-50"
              )}
              value={value}
              onChangeText={onChange}
              onFocus={() => {
                onKeyboardChange?.(true);
              }}
              onBlur={() => {
                onBlur?.();
                onKeyboardChange?.(false);
              }}
            />
          )}
          name="momentText"
        />
        <TimeAgoSelector control={control} setValue={setValue} />
        <View className="flex justify-center items-end">
          <SubmitMomentButton
            isSubmitting={isSubmitting}
            handleSubmit={handleSubmit}
            isSubmitted={isSubmitted}
            isTextFilled={isTextFilled}
          />
        </View>
      </View>
    </FormProvider>
  );
};

export default SubmitEntryForm;
