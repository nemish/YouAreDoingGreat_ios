import useHighlightedItemStore from "@/hooks/stores/useHighlightedItem";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useMenuStore from "@/hooks/stores/useMenuStore";
import useModalStore from "@/hooks/stores/useModalStore";
import useFetchApi from "@/hooks/useFetchApi";
import useUserProfile from "@/hooks/useUserProfile";
import logger from "@/utils/logger";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { getCalendars } from "expo-localization";

type Moment = {
  id: string;
  text: string;
  submittedAt: string;
  tz?: string;
};

type MomentResponse = {
  item: Moment;
};

type ApiError = {
  error: {
    code: string;
    message: string;
  };
  meta?: {
    limit?: number;
    isPremium?: boolean;
  };
};

type Args = {
  text: string;
  timeAgoSeconds?: number;
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getMutationFn =
  (fetchApi: FetchApiFunction) =>
  async ({ text, timeAgoSeconds }: Args): Promise<MomentResponse> => {
    try {
      const body: any = {
        text,
        submittedAt: new Date().toISOString(),
        tz: getCalendars()[0]?.timeZone,
      };

      // Add timeAgo as integer seconds if user selected a time in the past
      if (timeAgoSeconds) {
        body.timeAgo = timeAgoSeconds;
      }
      const response = await fetchApi({
        path: "/moments",
        method: "POST",
        body,
        headers: {
          "Content-Type": "application/json",
        },
      });

      if (!response.ok) {
        logger.debug("Error response from submit moment:", response);

        // Parse error response if available
        let errorData: ApiError | null = null;
        try {
          errorData = await response.json();
        } catch {
          // If response is not JSON, create generic error
          errorData = {
            error: {
              code: `HTTP_${response.status}`,
              message: response.statusText || "Failed to submit moment",
            },
          };
        }

        throw errorData;
      }
      return response.json();
    } catch (error) {
      logger.error("Failed to submit moment:", error);
      throw error;
    }
  };

const useSubmitMomentMutation = () => {
  const queryClient = useQueryClient();
  const openModal = useModalStore((state) => state.openModal);
  const setActiveItem = useMenuStore((state) => state.setActiveItem);
  const setMainPanelState = useMainPanelStore(
    (state) => state.setMainPanelState
  );
  const setIsShown = useMainPanelStore((state) => state.setIsShown);
  const setHighlightedItem = useHighlightedItemStore(
    (state) => state.setHighlightedItem
  );
  const fetchApi = useFetchApi();
  const mutationFn = getMutationFn(fetchApi);
  const { customerInfo } = useUserProfile();

  return useMutation({
    mutationFn,
    onSuccess: (data) => {
      logger.debug("Moment submitted successfully:", data);

      // Invalidate and refetch the userMoments query to get fresh data
      queryClient.invalidateQueries({ queryKey: ["userMoments"] });
      openModal("moment", data.item);
      setMainPanelState("init");
      setActiveItem("/");
      setHighlightedItem(data.item);
    },
    onError: (error: any) => {
      logger.error("Failed to submit moment:", error);

      // Only show paywall for daily limit errors for non-premium users
      if (
        error?.error?.code === "DAILY_LIMIT_REACHED" &&
        !customerInfo?.entitlements?.active?.premium
      ) {
        logger.debug("Daily limit reached - showing paywall");
        setMainPanelState("paywall", {
          isDailyLimitReached: true,
        });
        setIsShown(true);
      }

      // All other errors are silently logged and not shown to users
    },
  });
};

export default useSubmitMomentMutation;
