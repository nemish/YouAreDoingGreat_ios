import { create } from "zustand";

type UserIdStore = {
  userId: string | null;
  isInitialized: boolean;
  setUserId: (userId: string, isInitialized?: boolean) => void;
};

const useUserIdStore = create<UserIdStore>((set) => ({
  userId: null,
  isInitialized: false,
  setUserId: (userId: string, isInitialized?: boolean) =>
    set({ userId, isInitialized: isInitialized ?? false }),
}));

export default useUserIdStore;
