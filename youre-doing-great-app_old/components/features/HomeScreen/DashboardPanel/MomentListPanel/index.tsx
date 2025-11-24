import { ActivityIndicator, View } from "react-native";
import MomentsList from "./MomentsList";
import { useInfiniteMoments } from "./hooks/useUserMomentsQuery";
import ErrorFallback from "@/components/ui/ErrorFallback";

const MomentsListPanel = () => {
  const {
    isLoading,
    moments,
    refetch,
    isFetching,
    fetchNextPage,
    hasNextPage,
    isFetchingNextPage,
    error,
    isError,
  } = useInfiniteMoments();

  // Show error state
  if (isError && error) {
    return <ErrorFallback error={error} onRetry={() => refetch()} />;
  }

  // Show loading state
  if (isLoading) {
    return (
      <View className="flex-1 flex items-center justify-center">
        <ActivityIndicator size="small" color="#9ca3af" />
      </View>
    );
  }

  // Show moments list
  return (
    <MomentsList
      items={moments}
      onRefresh={refetch}
      refreshing={isFetching}
      onLoadMore={fetchNextPage}
      hasNextPage={hasNextPage}
      isLoadingMore={isFetchingNextPage}
    />
  );
};

export default MomentsListPanel;
