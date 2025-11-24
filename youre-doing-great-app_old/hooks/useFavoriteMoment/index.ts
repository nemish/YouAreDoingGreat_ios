import useUpdateMomentFavoriteMutation from "@/components/features/Modals/MomentModal/ActionButtons/hooks/useUpdateMomentFavoriteMutation";
import { Moment } from "@/constants/types";
import { useCallback } from "react";

type UseFavoriteMomentProps = {
  onSuccess?: () => void;
  onError?: (error: Error) => void;
};

const useFavoriteMoment = ({
  onSuccess,
  onError,
}: UseFavoriteMomentProps = {}) => {
  const { mutateAsync: updateFavorite, isPending } =
    useUpdateMomentFavoriteMutation();

  const toggleFavorite = useCallback(
    async (moment: Moment) => {
      try {
        await updateFavorite({
          id: moment.id,
          isFavorite: !moment.isFavorite,
        });
        onSuccess?.();
      } catch (error) {
        console.error("Failed to update favorite status:", error);
        onError?.(error as Error);
      }
    },
    [updateFavorite, onSuccess, onError]
  );

  const setFavorite = useCallback(
    async (moment: Moment, isFavorite: boolean) => {
      try {
        await updateFavorite({
          id: moment.id,
          isFavorite,
        });
        onSuccess?.();
      } catch (error) {
        console.error("Failed to update favorite status:", error);
        onError?.(error as Error);
      }
    },
    [updateFavorite, onSuccess, onError]
  );

  return {
    toggleFavorite,
    setFavorite,
    isPending,
  };
};

export default useFavoriteMoment;
