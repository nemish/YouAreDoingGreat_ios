import { create } from "zustand";

export type MenuItemName = "new-moment" | "/" | "/timeline" | "/profile";
// | "materials"

type MenuStore = {
  activeItem: MenuItemName;
  setActiveItem: (item: MenuItemName) => void;
};

const useMenuStore = create<MenuStore>((set) => ({
  activeItem: "/",
  setActiveItem: (item: MenuItemName) => set({ activeItem: item }),
}));

export default useMenuStore;
