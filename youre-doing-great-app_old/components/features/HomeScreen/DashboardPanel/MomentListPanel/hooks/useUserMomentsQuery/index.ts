import type { Moment } from "@/constants/types";
import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useInfiniteQuery } from "@tanstack/react-query";

type PaginatedResponse = {
  data: Moment[];
  nextCursor?: string;
  hasNextPage: boolean;
};

type QueryParams = {
  cursor?: string;
  limit?: number;
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getQueryFn =
  (fetchApi: FetchApiFunction) =>
  async ({ pageParam }: { pageParam?: QueryParams }): Promise<PaginatedResponse> => {
    const params = new URLSearchParams();
    if (pageParam?.cursor) {
      params.append("cursor", pageParam.cursor);
    }
    if (pageParam?.limit) {
      params.append("limit", pageParam.limit.toString());
    }

    logger.debug("Fetching moments with params:", params.toString());
    try {
      const response = await fetchApi({
        path: `/moments?${params.toString()}`,
      });
      if (!response.ok) {
        throw new Error("Failed to fetch moments");
      }

      return response.json() as Promise<PaginatedResponse>;
    } catch (error) {
      logger.error("Failed to fetch moments:", error);
      throw error;
    }
  };

// Custom hook for easy infinite scrolling implementation
export const useInfiniteMoments = (limit: number = 50) => {
  const fetchApi = useFetchApi();
  const queryFn = getQueryFn(fetchApi);
  const query = useInfiniteQuery({
    queryKey: ["userMoments"],
    queryFn,
    initialPageParam: { limit } as QueryParams,
    getNextPageParam: (lastPage) => {
      if (!lastPage.hasNextPage) {
        return undefined;
      }
      return {
        cursor: lastPage.nextCursor,
        limit,
      };
    },
    select: (data) => ({
      pages: data.pages,
      pageParams: data.pageParams,
      // Flatten all moments from all pages
      moments: data.pages.flatMap((page) => page.data),
      // Check if there are more pages to load
      hasNextPage: data.pages[data.pages.length - 1]?.hasNextPage ?? false,
    }),
    // Memory optimization: Keep only last 20 pages in memory
    // With 50 items per page = 1,000 moments max in memory (~1 MB)
    // Prevents memory growth on long scrolling sessions while allowing
    // better backwards scrolling capability for power users
    maxPages: 20,
    // Prevent refetching on mount if data is already available
    refetchOnMount: false,
    // Moments list is dynamic (users add/delete/favorite)
    staleTime: 1 * 60 * 1000, // 1 minute - fresh enough to show recent changes
    gcTime: 5 * 60 * 1000, // 5 minutes - keep scrolled pages briefly
  });

  return {
    // Data
    moments: query.data?.moments ?? [],
    pages: query.data?.pages ?? [],

    // Loading states
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isFetchingNextPage: query.isFetchingNextPage,

    // Pagination state
    hasNextPage: query.data?.hasNextPage ?? false,

    // Actions
    fetchNextPage: query.fetchNextPage,

    // Error handling
    error: query.error,
    isError: query.isError,

    // Refetch
    refetch: query.refetch,

    // Status
    status: query.status,
  };
};
