import { getRandomFromArray } from "@/utils/texts";
import { useEffect, useState } from "react";

const startPhrases = ["Nice...", "Alright...", "Good...", "Awesome..."];

const loadingPhrases = [
  "Thinking...",
  "One sec...",
  "Almost...",
  "Still here...",
  "Finding it...",
  "Just a moment...",
  "Hold tight...",
  "Looking closer...",
  "Warming words...",
  "Lining it up...",
  "Tiny spark...",
  "Softly now...",
  "Turning pages...",
  "Gathering light...",
  "On it...",
  "Tuning in...",
  "Quiet magic...",
  "Almost ready...",
  "Hang on...",
];

type Props = {
  isSubmitting: boolean;
};

const useLoadingText = ({ isSubmitting }: Props) => {
  const [loadingText, setLoadingText] = useState(
    getRandomFromArray(startPhrases)
  );

  useEffect(() => {
    if (!isSubmitting) {
      return;
    }

    const interval = setInterval(() => {
      setLoadingText(
        loadingPhrases[Math.floor(Math.random() * loadingPhrases.length)]
      );
    }, 2000);

    return () => clearInterval(interval);
  }, [isSubmitting]);
  return loadingText;
};

export default useLoadingText;
