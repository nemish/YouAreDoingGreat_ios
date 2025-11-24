import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useQuery } from "@tanstack/react-query";

type User = {
  _id: string;
  createdAt: string;
  userId: string;
  status: "newcomer" | "paywall_needed" | "premium";
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getQueryFn =
  (fetchApi: FetchApiFunction) =>
  async (): Promise<User | null> => {
    try {
      const response = await fetchApi({
        path: "/user/me",
        headers: {
          "Content-Type": "application/json",
        },
      });
      const data = await response.json();
      return data?.item || null;
    } catch (error) {
      logger.error("Failed to fetch current user:", error);
      return null;
    }
  };

export const useCurrentUserQuery = () => {
  const fetchApi = useFetchApi();
  const queryFn = getQueryFn(fetchApi);
  return useQuery<User | null>({
    queryKey: ["currentUser"],
    queryFn,
    // User profile data is relatively stable
    staleTime: 5 * 60 * 1000, // 5 minutes - user status/profile changes occasionally
    gcTime: 10 * 60 * 1000, // 10 minutes - keep in cache for quick access
  });
};
