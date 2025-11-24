import FancyButton from "@/components/ui/FancyButton";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import { usePurchaseSubscription } from "@/hooks/usePurchaseSubscription";
import React, { useCallback, useEffect } from "react";
import { Controller, useForm } from "react-hook-form";
import { Pressable, Text, View } from "react-native";
import usePlans from "./hooks/usePlans";

const ChoosePlanForm = () => {
  const plans = usePlans();
  const {
    control,
    handleSubmit,
    setValue,
    formState: { isSubmitting, isSubmitted },
  } = useForm<{ plan: string }>({
    defaultValues: {
      plan: "",
    },
  });

  // Set the form value to the first plan when plans data loads
  useEffect(() => {
    if (plans.data && plans.data.length > 0) {
      setValue("plan", plans.data[0].value);
    }
  }, [plans.data, setValue]);

  const { mutate, isPending } = usePurchaseSubscription();
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  const setMainPanelState = useMainPanelStore(
    (state) => state.setMainPanelState
  );
  const onSubmit = useCallback(
    (data: { plan: string }) => {
      mutate(
        { plan: data.plan },
        {
          onSuccess: (result) => {
            if (result.success) {
              // Close paywall and return to main screen after a short delay
              setTimeout(() => {
                setIsShown(false);
                setMainPanelState("init");
              }, 2000);
            }
          },
          onError: (error) => {
            console.error("Purchase error:", error);
          },
        }
      );
    },
    [mutate, setIsShown, setMainPanelState]
  );

  return (
    <View className="w-full px-4 gap-6">
      <Controller
        name="plan"
        control={control}
        render={({ field: { value, onChange } }) => (
          <View className="gap-4">
            {plans.data?.map((plan) => {
              const isSelected = value === plan.value;
              return (
                <Pressable
                  key={plan.value}
                  onPress={() => {
                    console.log("Selected plan:", plan.value);
                    onChange(plan.value);
                  }}
                  className={`flex-row items-center justify-between border-2 rounded-2xl p-4 ${
                    isSelected
                      ? "border-vitality-500 bg-vitality-500/10"
                      : "border-white/30"
                  }`}
                >
                  {/* Left: Checkmark + Label */}
                  <View className="flex-row items-center">
                    <View
                      className={`w-5 h-5 rounded-full items-center justify-center mr-3 ${
                        isSelected
                          ? "bg-vitality-400"
                          : "border-white/50 border-2"
                      }`}
                    >
                      {isSelected && (
                        <View className="w-2.5 h-2.5 bg-white rounded-full" />
                      )}
                    </View>
                    <Text
                      style={{ fontFamily: "Comfortaa" }}
                      className="text-lg font-bold text-white"
                    >
                      {plan.label}
                    </Text>
                    {plan.label === "Yearly" && (
                      <View className="px-2 py-1 bg-vitality-400/40 rounded-full ml-2">
                        <Text
                          style={{ fontFamily: "Comfortaa" }}
                          className="text-xs text-vitality-200 font-bold"
                        >
                          save 20%
                        </Text>
                      </View>
                    )}
                  </View>

                  <View className="flex-row items-baseline">
                    <Text
                      style={{ fontFamily: "Comfortaa" }}
                      className="text-lg font-bold text-white"
                    >
                      {plan.priceDisplay}
                    </Text>
                  </View>
                </Pressable>
              );
            })}
          </View>
        )}
      />

      <FancyButton
        fullWidth
        size="lg"
        isDisabled={isSubmitting || isPending}
        onPress={handleSubmit(onSubmit)}
        text={
          isSubmitting || isPending
            ? "Processing..."
            : isSubmitted
            ? "Success"
            : "Start 7-Day Free Trial"
        }
      />
    </View>
  );
};

export default ChoosePlanForm;
