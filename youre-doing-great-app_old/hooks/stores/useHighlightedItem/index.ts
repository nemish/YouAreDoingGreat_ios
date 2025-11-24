import { Moment } from "@/constants/types";
import { create } from "zustand";

type HighlightedItemStore = {
  highlightedItem: Moment | null;
  setHighlightedItem: (highlightedItem: Moment | null) => void;
};

const useHighlightedItemStore = create<HighlightedItemStore>((set) => ({
  highlightedItem: null,
  setHighlightedItem: (highlightedItem) => set({ highlightedItem }),
}));

export default useHighlightedItemStore;
