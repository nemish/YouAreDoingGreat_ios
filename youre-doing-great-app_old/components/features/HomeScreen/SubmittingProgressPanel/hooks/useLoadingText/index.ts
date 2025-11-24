import { useEffect, useState } from "react";

const loadingPhrases = [
  "Loading...",
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

const useLoadingText = () => {
  const [loadingText, setLoadingText] = useState(loadingPhrases[0]);

  useEffect(() => {
    const interval = setInterval(() => {
      setLoadingText(
        loadingPhrases[Math.floor(Math.random() * loadingPhrases.length)]
      );
    }, 2000);

    return () => clearInterval(interval);
  }, []);

  return loadingText;
};

export default useLoadingText;
