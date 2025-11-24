import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useMutation, useQueryClient } from "@tanstack/react-query";

type Response = {
  message: string;
};

type Args = {
  id: string;
  isFavorite: boolean;
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getMutationFn =
  (fetchApi: FetchApiFunction) =>
  async ({ id, isFavorite }: Args): Promise<Response> => {
    try {
      const response = await fetchApi({
        path: `/moments/${id}`,
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
        },
        body: { isFavorite },
      });

      if (!response.ok) {
        throw new Error("Failed to update moment favorite status");
      }

      return response.json();
    } catch (error) {
      logger.error("Failed to update moment favorite:", error);
      throw error;
    }
  };

const useUpdateMomentFavoriteMutation = () => {
  const queryClient = useQueryClient();
  const fetchApi = useFetchApi();
  const mutationFn = getMutationFn(fetchApi);
  return useMutation({
    mutationFn,
    onMutate: async ({ id, isFavorite }) => {
      // Cancel outgoing refetches
      await queryClient.cancelQueries({ queryKey: ["userMoments"] });

      // Snapshot previous value
      const previousMoments = queryClient.getQueryData(["userMoments"]);

      // Optimistically update
      queryClient.setQueryData(["userMoments"], (oldData: any) => {
        if (!oldData) return oldData;

        // Update each page by updating the favorite status of the specific moment
        const updatedPages = oldData.pages.map((page: any) => ({
          ...page,
          data: page.data.map((moment: any) =>
            moment.id === id ? { ...moment, isFavorite } : moment
          ),
        }));

        // Recalculate the flattened moments array
        const updatedMoments = updatedPages.flatMap((page: any) => page.data);

        return {
          ...oldData,
          pages: updatedPages,
          moments: updatedMoments,
        };
      });

      return { previousMoments };
    },
    onError: (err, variables, context) => {
      // Rollback on error
      if (context?.previousMoments) {
        queryClient.setQueryData(["userMoments"], context.previousMoments);
      }
    },
    onSettled: () => {
      // TODO: commented this because it looks a bit unperformant
      // Always refetch after error or success
      //   queryClient.invalidateQueries({ queryKey: ["userMoments"] });
    },
    onSuccess: (response, variables) => {
      logger.debug("Successfully updated moment favorite:", response);
    },
  });
};

export default useUpdateMomentFavoriteMutation;
