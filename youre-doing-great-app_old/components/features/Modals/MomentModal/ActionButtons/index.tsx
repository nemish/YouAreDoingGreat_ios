import type { Moment } from "@/constants/types";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useModalStore from "@/hooks/stores/useModalStore";
import useFavoriteMoment from "@/hooks/useFavoriteMoment";
import { Heart, HeartMinus, Trash2, X } from "lucide-react-native";
import { MotiView } from "moti";
import { ActivityIndicator, Pressable, Text, View } from "react-native";
import useDeleteMomentMutation from "./hooks/useDeleteMomentMutation";

type Props = {
  item: Moment;
};

const ActionButtons = ({ item }: Props) => {
  const closeModal = useModalStore((state) => state.closeModal);
  const { mutateAsync: deleteMoment, isPending: isDeleting } =
    useDeleteMomentMutation();
  const { toggleFavorite, isPending: isUpdatingFavorite } = useFavoriteMoment({
    onError: (error) => {
      console.error("Failed to update favorite status:", error);
      // Don't close modal on error, let user retry
    },
    onSuccess: () => {
      closeModal();
    },
  });
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  console.log("MomentModal", { item });

  const handleDelete = async () => {
    await deleteMoment({ id: item?.id });
    closeModal();
  };

  const handleFavourite = async () => {
    await toggleFavorite(item);
  };

  const isFavorite = item?.isFavorite || false;
  const isPending = isDeleting || isUpdatingFavorite;
  return (
    <MotiView
      from={{ translateY: 50, opacity: 0 }}
      animate={{ translateY: 0, opacity: 1 }}
      exit={{ translateY: 50, opacity: 0 }}
      transition={{
        type: "spring",
        damping: 25,
        stiffness: 250,
        mass: 0.8,
        delay: 100,
      }}
      className="bg-gray-900 rounded-2xl overflow-hidden shadow-2xl w-2/3 self-end"
    >
      {/* Favorite Button */}
      <Pressable onPress={handleFavourite} disabled={isPending}>
        <View className="flex-row items-center justify-between px-6 py-4 border-b border-gray-800">
          <Text
            style={{ fontFamily: "Comfortaa" }}
            className={`text-lg font-medium ${
              isUpdatingFavorite ? "text-gray-500" : "text-white"
            }`}
          >
            {isFavorite ? "Unfavorite" : "Favorite"}
          </Text>
          {isUpdatingFavorite ? (
            <ActivityIndicator size="small" color="#9ca3af" />
          ) : isFavorite ? (
            <HeartMinus size={24} color="#f87171" />
          ) : (
            <Heart size={24} color="white" />
          )}
        </View>
      </Pressable>

      {/* Delete Button */}
      <Pressable onPress={handleDelete} disabled={isPending}>
        <View className="flex-row items-center justify-between px-6 py-4">
          <Text
            style={{ fontFamily: "Comfortaa" }}
            className={`text-lg font-medium ${
              isDeleting ? "text-gray-500" : "text-red-400"
            }`}
          >
            Delete
          </Text>
          {isDeleting ? (
            <ActivityIndicator size="small" color="#9ca3af" />
          ) : (
            <Trash2 size={24} color="#f87171" />
          )}
        </View>
      </Pressable>

      {/* Close Button */}
      <Pressable
        onPress={() => {
          closeModal();
          setIsShown(false);
        }}
      >
        <View className="flex-row items-center justify-between px-6 py-4">
          <Text
            style={{ fontFamily: "Comfortaa" }}
            className={`text-lg font-medium text-white`}
          >
            Close
          </Text>
          <X size={24} color="#fff" />
        </View>
      </Pressable>
    </MotiView>
  );
};

export default ActionButtons;
