import { useMemo } from "react";
import { StyleSheet, ViewStyle } from "react-native";

export type TimeOfDay =
  | "early-morning"
  | "morning"
  | "afternoon"
  | "evening"
  | "night";

export type TimeOfDayStyles = {
  backgroundStyle: ViewStyle;
  borderStyle: ViewStyle;
  timeOfDay: TimeOfDay;
};

const getTimeOfDayStyles = (hour: number): TimeOfDayStyles => {
  if (hour >= 5 && hour < 8) {
    // Early morning: 5-8 AM
    return {
      backgroundStyle: styles.earlyMorningBackground,
      borderStyle: styles.earlyMorningBorder,
      timeOfDay: "early-morning",
    };
  } else if (hour >= 8 && hour < 12) {
    // Morning: 8-12 PM
    return {
      backgroundStyle: styles.morningBackground,
      borderStyle: styles.morningBorder,
      timeOfDay: "morning",
    };
  } else if (hour >= 12 && hour < 17) {
    // Afternoon: 12-5 PM
    return {
      backgroundStyle: styles.afternoonBackground,
      borderStyle: styles.afternoonBorder,
      timeOfDay: "afternoon",
    };
  } else if (hour >= 17 && hour < 20) {
    // Evening: 5-8 PM
    return {
      backgroundStyle: styles.eveningBackground,
      borderStyle: styles.eveningBorder,
      timeOfDay: "evening",
    };
  } else {
    // Night: 8 PM - 5 AM
    return {
      backgroundStyle: styles.nightBackground,
      borderStyle: styles.nightBorder,
      timeOfDay: "night",
    };
  }
};

const useTimeOfDayStyles = (submittedAt: string): TimeOfDayStyles => {
  return useMemo(() => {
    const hour = new Date(submittedAt).getHours();
    return getTimeOfDayStyles(hour);
  }, [submittedAt]);
};

const styles = StyleSheet.create({
  earlyMorningBackground: {
    backgroundColor: "#2a9d8f", // darker green
  },
  morningBackground: {
    backgroundColor: "#0077b6", // darker orange
  },
  afternoonBackground: {
    backgroundColor: "#e76f51", // yellow-700 - yellow dominant for sun
  },
  eveningBackground: {
    backgroundColor: "#ae2012", // darker red
  },
  nightBackground: {
    backgroundColor: "#003566", // darker indigo/purple
  },
  earlyMorningBorder: {
    borderColor: "#2a9d8f", // matches background
    borderWidth: 2,
  },
  morningBorder: {
    borderColor: "#0077b6", // matches background
    borderWidth: 2,
  },
  afternoonBorder: {
    borderColor: "#e76f51", // matches background
    borderWidth: 2,
  },
  eveningBorder: {
    borderColor: "#ae2012", // matches background
    borderWidth: 2,
  },
  nightBorder: {
    borderColor: "#003566", // matches background
    borderWidth: 2,
  },
});

export default useTimeOfDayStyles;
