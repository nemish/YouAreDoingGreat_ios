import useFetchApi from "@/hooks/useFetchApi";
import type {
  CreateUserFeedbackRequest,
  CreateUserFeedbackResponse,
} from "@/constants/types";
import logger from "@/utils/logger";
import { useMutation } from "@tanstack/react-query";

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getMutationFn =
  (fetchApi: FetchApiFunction) =>
  async (
    data: CreateUserFeedbackRequest
  ): Promise<CreateUserFeedbackResponse> => {
    try {
      const response = await fetchApi({
        path: "/user/feedback",
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: data,
      });

      if (!response.ok) {
        throw new Error("Failed to submit feedback");
      }

      return response.json();
    } catch (error) {
      logger.error("Failed to submit feedback:", error);
      throw error;
    }
  };

const useSubmitFeedbackMutation = () => {
  const fetchApi = useFetchApi();
  const mutationFn = getMutationFn(fetchApi);

  return useMutation({
    mutationFn,
    onSuccess: (response) => {
      logger.debug("Feedback submitted successfully:", response);
    },
    onError: (error) => {
      logger.error("Failed to submit feedback:", error);
    },
  });
};

export default useSubmitFeedbackMutation;
