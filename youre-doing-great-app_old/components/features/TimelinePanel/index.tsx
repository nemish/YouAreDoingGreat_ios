import CommonText from "@/components/ui/CommonText";
import { useTimeline } from "@/hooks/useTimeline";
import React, { useMemo } from "react";
import {
  ActivityIndicator,
  FlatList,
  RefreshControl,
  View,
} from "react-native";
import TimelineItem from "./TimelineItem";

const TimelinePanel = () => {
  const {
    items,
    isLoading,
    isFetching,
    isFetchingNextPage,
    hasNextPage,
    fetchNextPage,
    refetch,
  } = useTimeline();

  // Insert today marker into timeline
  const itemsWithTodayMarker = useMemo(() => {
    const today = new Date();
    const todayStr = today.toISOString().split("T")[0];

    // Find the position to insert today marker
    const insertIndex = items.findIndex((item) => {
      const itemDate = new Date(item.date);
      itemDate.setHours(0, 0, 0, 0);
      return itemDate < today;
    });

    const todayMarker = {
      id: "__today__",
      date: todayStr,
      text: null,
      tags: [],
      momentsCount: 0,
      timesOfDay: [],
      createdAt: new Date().toISOString(),
      isToday: true,
    };

    if (insertIndex === -1) {
      // Today is the last item or list is empty
      return [...items, todayMarker];
    }

    // Insert today marker at the correct position
    return [
      ...items.slice(0, insertIndex),
      todayMarker,
      ...items.slice(insertIndex),
    ];
  }, [items]);

  const handleLoadMore = () => {
    if (hasNextPage && !isFetchingNextPage) {
      fetchNextPage();
    }
  };

  if (isLoading) {
    return (
      <View className="flex-1 items-center justify-center">
        <ActivityIndicator size="small" color="#ffffff" />
      </View>
    );
  }

  return (
    <View className="flex-1 pt-20 pb-28">
      <CommonText className="text-center text-3xl font-bold text-white mb-6 px-6">
        Timeline
      </CommonText>

      <FlatList
        data={itemsWithTodayMarker}
        keyExtractor={(item) => item.id}
        renderItem={({ item, index }) => (
          <TimelineItem item={item} index={index} />
        )}
        contentContainerStyle={{ paddingHorizontal: 16, paddingBottom: 20 }}
        showsVerticalScrollIndicator={false}
        onEndReached={handleLoadMore}
        onEndReachedThreshold={0.5}
        refreshControl={
          <RefreshControl
            refreshing={isFetching && !isFetchingNextPage}
            onRefresh={refetch}
            tintColor="#ffffff"
          />
        }
        ListFooterComponent={
          isFetchingNextPage ? (
            <View className="py-4 items-center">
              <ActivityIndicator size="small" color="#ffffff" />
            </View>
          ) : null
        }
        ListEmptyComponent={
          <View className="flex-1 items-center justify-center py-12">
            <CommonText className="text-white/60 text-center">
              No timeline data yet
            </CommonText>
          </View>
        }
      />
    </View>
  );
};

export default TimelinePanel;
