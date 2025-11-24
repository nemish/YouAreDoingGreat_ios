import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useQuery } from "@tanstack/react-query";

export type UserStats = {
  totalMoments: number;
  momentsToday: number;
  momentsYesterday: number;
  currentStreak: number;
  longestStreak: number;
  lastMomentDate: string | null;
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getQueryFn =
  (fetchApi: FetchApiFunction) =>
  async (): Promise<UserStats | null> => {
    try {
      const response = await fetchApi({
        path: "/user/stats",
        headers: {
          "Content-Type": "application/json",
        },
      });
      const data = await response.json();
      return data?.item || null;
    } catch (error) {
      logger.error("Failed to fetch user stats:", error);
      return null;
    }
  };

export const useUserStatsQuery = () => {
  const fetchApi = useFetchApi();
  const queryFn = getQueryFn(fetchApi);
  return useQuery<UserStats | null>({
    queryKey: ["userStats"],
    queryFn,
    // User stats change when moments are added, but not constantly
    staleTime: 5 * 60 * 1000, // 5 minutes - stats update periodically
    gcTime: 10 * 60 * 1000, // 10 minutes - keep in cache for quick access
  });
};
