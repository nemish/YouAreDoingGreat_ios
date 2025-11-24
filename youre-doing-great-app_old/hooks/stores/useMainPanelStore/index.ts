import { create } from "zustand";

type MainPanelState =
  | "init"
  | "paywall"
  | "submitForm"
  | "submittingProgress"
  | "momentSubmitted";

type MainPanelStore = {
  isInitMomentPanelShown: boolean;
  mainPanelState: MainPanelState;
  extraData: any;
  setIsShown: (isInitMomentPanelShown: boolean) => void;
  setMainPanelState: (mainPanelState: MainPanelState, extraData?: any) => void;
};

const useMainPanelStore = create<MainPanelStore>((set) => ({
  isInitMomentPanelShown: true,
  mainPanelState: "init",
  extraData: null,
  setIsShown: (isInitMomentPanelShown) => set({ isInitMomentPanelShown }),
  setMainPanelState: (mainPanelState, extraData) =>
    set({ mainPanelState, extraData }),
}));

export default useMainPanelStore;
