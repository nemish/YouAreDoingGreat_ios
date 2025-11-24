import { useMemo } from "react";

export type FormattedDate = {
  time: string;
  ampm: string;
  date: string;
};

const useFormattedDate = (submittedAt: string) => {
  return useMemo(() => {
    const date = new Date(submittedAt);
    const hours = date.getHours();
    const minutes = date.getMinutes();
    const ampm = hours >= 12 ? "PM" : "AM";
    const displayHours = hours % 12 || 12;

    return {
      time: `${displayHours}:${minutes.toString().padStart(2, "0")}`,
      ampm: ampm,
      date: date.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      }),
    };
  }, [submittedAt]);
};

export default useFormattedDate;
