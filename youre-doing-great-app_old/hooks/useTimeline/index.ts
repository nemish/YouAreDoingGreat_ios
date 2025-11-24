import type { PaginatedTimelineResponse } from "@/constants/types";
import useFetchApi from "@/hooks/useFetchApi";
import logger from "@/utils/logger";
import { useInfiniteQuery } from "@tanstack/react-query";

type QueryParams = {
  cursor?: string;
  limit?: number;
};

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getQueryFn =
  (fetchApi: FetchApiFunction) =>
  async ({ pageParam }: { pageParam?: QueryParams }): Promise<PaginatedTimelineResponse> => {
    const params = new URLSearchParams();
    if (pageParam?.cursor) {
      params.append("cursor", pageParam.cursor);
    }
    if (pageParam?.limit) {
      params.append("limit", pageParam.limit.toString());
    }

    try {
      const response = await fetchApi({
        path: `/timeline?${params.toString()}`,
      });
      if (!response.ok) {
        throw new Error("Failed to fetch timeline");
      }

      return response.json() as Promise<PaginatedTimelineResponse>;
    } catch (error) {
      logger.error("Failed to fetch timeline:", error);
      throw error;
    }
  };

export const useTimeline = (limit: number = 20) => {
  const fetchApi = useFetchApi();
  const queryFn = getQueryFn(fetchApi);
  const query = useInfiniteQuery({
    queryKey: ["timeline"],
    queryFn,
    initialPageParam: { limit } as QueryParams,
    getNextPageParam: (lastPage) => {
      if (!lastPage.hasNextPage || !lastPage.nextCursor) {
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
      items: data.pages.flatMap((page) => page.data),
      hasNextPage: data.pages[data.pages.length - 1]?.hasNextPage ?? false,
    }),
    // Memory optimization: Keep only last 20 pages in memory
    // With 20 items per page = 400 timeline days max in memory (~200 KB)
    // Prevents memory growth on long scrolling sessions while allowing
    // better backwards scrolling for reviewing history
    maxPages: 20,
    refetchOnMount: false,
    // Timeline is dynamic (moments added/deleted change timeline)
    staleTime: 1 * 60 * 1000, // 1 minute - fresh enough to show recent changes
    gcTime: 5 * 60 * 1000, // 5 minutes - keep scrolled pages briefly
  });

  return {
    items: query.data?.items ?? [],
    pages: query.data?.pages ?? [],
    isLoading: query.isLoading,
    isFetching: query.isFetching,
    isFetchingNextPage: query.isFetchingNextPage,
    hasNextPage: query.data?.hasNextPage ?? false,
    fetchNextPage: query.fetchNextPage,
    error: query.error,
    isError: query.isError,
    refetch: query.refetch,
    status: query.status,
  };
};
