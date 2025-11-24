import type { Moment } from "@/constants/types";
import useFetchApi from "@/hooks/useFetchApi";
import { useQuery } from "@tanstack/react-query";

type FetchApiFunction = ReturnType<typeof useFetchApi>;

const getQueryFn =
  (fetchApi: FetchApiFunction) =>
  async (id: string): Promise<Moment | null> => {
    const response = await fetchApi({
      path: `/moments/${id}`,
      headers: {
        "Content-Type": "application/json",
      },
    });
    const data = await response.json();
    return data?.item || null;
  };

const useMomentQuery = (id: string) => {
  const fetchApi = useFetchApi();
  const queryFn = getQueryFn(fetchApi);
  return useQuery<Moment | null>({
    queryKey: ["moment", id],
    queryFn: () => queryFn(id),
    // Individual moments can change (AI generates praise, favorite status)
    staleTime: 2 * 60 * 1000, // 2 minutes - moments can be updated
    gcTime: 5 * 60 * 1000, // 5 minutes - keep recently viewed moments
  });
};

export default useMomentQuery;
