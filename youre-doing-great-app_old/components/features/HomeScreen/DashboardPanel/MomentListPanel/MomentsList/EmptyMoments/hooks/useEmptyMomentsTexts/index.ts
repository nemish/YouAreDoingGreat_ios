import getRandomFromArray from "@/utils/getRandomFromArray";
import { useMemo } from "react";

const TITLES = [
  "No moments yet… but you’re here, so that’s one.",
  "No entries yet. You’re still awesome — just undocumented.",
  "Blank? Sure. But so was the canvas before the Mona Lisa.",
];

const DESCRIPTIONS = [
  "Your moments will appear here once you log them. For now, it’s just cozy and empty.",
  "Once you start logging, your moments will show up here. Until then, enjoy the emptiness.",
];

const useEmptyMomentsTexts = () => {
  const title = useMemo(() => getRandomFromArray(TITLES), []);
  const description = useMemo(() => getRandomFromArray(DESCRIPTIONS), []);
  return {
    title,
    description,
  };
};

export default useEmptyMomentsTexts;
