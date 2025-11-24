import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useMutation, useQueryClient } from "@tanstack/react-query";

type Response = {
  success: string | null;
  errors?: string[];
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getMutationFn =
  (fetchApi: FetchApiFunction) =>
  async ({ id }: { id: string }): Promise<Response> => {
    try {
      const response = await fetchApi({
        path: `/moments/${id}`,
        method: "DELETE",
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        throw new Error("Failed to delete moment");
      }

      return response.json();
    } catch (error) {
      logger.error("Failed to delete moment:", error);
      throw error;
    }
  };

const useDeleteMomentMutation = () => {
  const queryClient = useQueryClient();
  const fetchApi = useFetchApi();
  const mutationFn = getMutationFn(fetchApi);
  return useMutation({
    mutationFn,
    onSuccess: (response, variables) => {
      logger.debug("Successfully deleted moment:", response);

      // Manually update the cache instead of invalidating
      queryClient.setQueryData(["userMoments"], (oldData: any) => {
        if (!oldData) return oldData;

        // Update each page by filtering out the deleted moment
        const updatedPages = oldData.pages.map((page: any) => ({
          ...page,
          data: page.data.filter((moment: any) => moment.id !== variables.id),
        }));

        // Recalculate the flattened moments array
        const updatedMoments = updatedPages.flatMap((page: any) => page.data);

        return {
          ...oldData,
          pages: updatedPages,
          moments: updatedMoments,
        };
      });
    },
    onError: (error) => {
      logger.error("Failed to delete moment:", error);
    },
  });
};

export default useDeleteMomentMutation;
