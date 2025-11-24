import CommonText from "@/components/ui/CommonText";
import { Picker } from "@react-native-picker/picker";
import { MotiView } from "moti";
import { useState } from "react";
import { Control, Controller, UseFormSetValue } from "react-hook-form";
import { Modal, Pressable, View } from "react-native";

type TimeAgoSelectorProps = {
  control: Control<any>;
  setValue: UseFormSetValue<any>;
};

type NativePickerInputProps = {
  value: number | string;
  onChange: (value: any) => void;
  options: { label: string; value: number | string }[];
  placeholder?: string;
};

const NativePickerInput = ({
  value,
  onChange,
  options,
  placeholder,
}: NativePickerInputProps) => {
  const [showPicker, setShowPicker] = useState(false);
  const [tempValue, setTempValue] = useState(value);

  const selectedLabel =
    options.find((opt) => opt.value === value)?.label || placeholder || value;

  return (
    <>
      <Pressable
        onPress={() => setShowPicker(true)}
        className="flex-1 bg-slate-700 rounded-lg px-4 py-4"
      >
        <CommonText className="text-white/80 text-center text-base">
          {selectedLabel}
        </CommonText>
      </Pressable>

      <Modal
        visible={showPicker}
        transparent
        animationType="fade"
        onRequestClose={() => setShowPicker(false)}
      >
        <View className="flex-1 justify-end bg-black/50">
          {/* Toolbar */}
          <View className="bg-slate-800 border-b border-slate-700 flex-row justify-between px-4 py-4">
            <Pressable
              onPress={() => {
                setTempValue(value);
                setShowPicker(false);
              }}
            >
              <CommonText className="text-cyan-400 text-base">
                Cancel
              </CommonText>
            </Pressable>
            <Pressable
              onPress={() => {
                onChange(tempValue);
                setShowPicker(false);
              }}
            >
              <CommonText className="text-cyan-400 text-base font-semibold">
                Done
              </CommonText>
            </Pressable>
          </View>

          {/* Picker */}
          <View className="bg-slate-800">
            <Picker
              selectedValue={tempValue}
              onValueChange={(itemValue) => setTempValue(itemValue)}
              style={{
                backgroundColor: "#1e293b",
                color: "#fff",
              }}
              itemStyle={{
                color: "#fff",
                fontSize: 20,
              }}
            >
              {options.map((option) => (
                <Picker.Item
                  key={option.value}
                  label={option.label}
                  value={option.value}
                  color="#fff"
                />
              ))}
            </Picker>
          </View>
        </View>
      </Modal>
    </>
  );
};

// Generate time ago options
const generateTimeAgoOptions = () => {
  const options: { label: string; value: number }[] = [];

  // 5-45 minutes in 5 minute increments
  [5, 10, 15, 20, 30, 45].forEach((minutes) => {
    options.push({
      label: `${minutes} minutes`,
      value: minutes * 60, // Convert to seconds
    });
  });

  // 1-12 hours in 30 minute increments
  for (let i = 1; i <= 12; i += 0.5) {
    const hours = i;
    const label =
      hours === 1
        ? "1 hour"
        : hours % 1 === 0
        ? `${hours} hours`
        : `${hours} hours`;
    options.push({
      label,
      value: hours * 60 * 60, // Convert to seconds
    });
  }

  // 13-48 hours in 1 hour increments
  for (let i = 13; i <= 48; i++) {
    options.push({
      label: `${i} hours`,
      value: i * 60 * 60, // Convert to seconds
    });
  }

  return options;
};

export const TimeAgoSelector = ({
  control,
  setValue,
}: TimeAgoSelectorProps) => {
  const [isJustNow, setIsJustNow] = useState(true);

  const timeAgoOptions = generateTimeAgoOptions();

  return (
    <View className="gap-3">
      {/* Toggle Button - Similar to image style */}
      <View className="flex-row bg-slate-800 rounded-xl p-2">
        <Pressable
          onPress={() => {
            setIsJustNow(true);
            setValue("timeAgoSeconds", undefined);
          }}
          className="flex-1"
        >
          <MotiView
            animate={{
              backgroundColor: isJustNow ? "#334155" : "transparent",
            }}
            transition={{ type: "timing", duration: 200 }}
            className="rounded-xl px-4 py-4"
          >
            <CommonText className="text-center text-white/80">
              Just now
            </CommonText>
          </MotiView>
        </Pressable>

        <Pressable
          onPress={() => {
            setIsJustNow(false);
            setValue("timeAgoSeconds", 300); // Default to 5 minutes
          }}
          className="flex-1"
        >
          <MotiView
            animate={{
              backgroundColor: !isJustNow ? "#334155" : "transparent",
            }}
            transition={{ type: "timing", duration: 200 }}
            className="rounded-xl px-4 py-4"
          >
            <CommonText className="text-center text-white/80">
              Earlier
            </CommonText>
          </MotiView>
        </Pressable>
      </View>

      {/* Time Selection Panel */}
      {!isJustNow && (
        <MotiView
          from={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ type: "timing", duration: 200 }}
          className="bg-slate-800 rounded-xl p-2"
        >
          <View className="flex-row gap-2 items-center">
            {/* Single Time Picker */}
            <Controller
              control={control}
              name="timeAgoSeconds"
              defaultValue={300} // 5 minutes
              render={({ field: { onChange, value } }) => (
                <NativePickerInput
                  value={value || 300}
                  onChange={onChange}
                  options={timeAgoOptions}
                  placeholder="5 minutes"
                />
              )}
            />

            {/* "ago" text */}
            <View className="min-w-20">
              <CommonText className="text-white/80 text-base text-center">
                ago
              </CommonText>
            </View>
          </View>
        </MotiView>
      )}
    </View>
  );
};
