import { Moment } from "@/constants/types";
import { useMemo } from "react";
import useFormattedDate, { FormattedDate } from "./hooks/useFormattedDate";
import useTimeOfDayStyles, {
  TimeOfDayStyles,
} from "./hooks/useTimeOfDayStyles";

type TimeOfDayElements = {
  styles: TimeOfDayStyles;
  icon: any;
  formattedDate: FormattedDate;
};

const useTimeOfDayElements = (item: Moment): TimeOfDayElements => {
  const styles = useTimeOfDayStyles(item.happenedAt);
  const formattedDate = useFormattedDate(item.happenedAt);

  // Memoize icon calculation to avoid creating new Date objects
  const icon = useMemo(() => {
    const hour = new Date(item.happenedAt).getHours();
    if (hour >= 5 && hour < 8) return "sunrise"; // Early morning
    if (hour >= 8 && hour < 12) return "cloud-sun"; // Morning
    if (hour >= 12 && hour < 17) return "sun-medium"; // Afternoon
    if (hour >= 17 && hour < 20) return "sunset"; // Evening
    return "moon"; // Night
  }, [item.happenedAt]);

  // Memoize the entire return object to prevent unnecessary re-renders
  return useMemo(
    () => ({
      styles,
      icon,
      formattedDate,
    }),
    [styles, icon, formattedDate]
  );
};

export default useTimeOfDayElements;
