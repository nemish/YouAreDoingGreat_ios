import { Moment } from "@/constants/types";
import { create } from "zustand";

type ModalType = "moment";

type ModalPayload = {
  moment: Moment;
};

type ModalStore = {
  modalType: ModalType | null;
  payload: Moment | null;
  isOpen: boolean;
  openModal: (modalType: ModalType, payload: Moment) => void;
  closeModal: () => void;
};

const useModalStore = create<ModalStore>((set) => ({
  modalType: null,
  payload: null,
  isOpen: false,
  openModal: (modalType: ModalType, payload: Moment) =>
    set({ isOpen: true, modalType, payload }),
  closeModal: () => set({ isOpen: false, modalType: null, payload: null }),
}));

export default useModalStore;
