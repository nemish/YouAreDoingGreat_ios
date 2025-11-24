import type { Moment } from "@/constants/types";
import useHighlightedItemStore from "@/hooks/stores/useHighlightedItem";
import useMainPanelStore from "@/hooks/stores/useMainPanelStore";
import useModalStore from "@/hooks/stores/useModalStore";
import { FlashList, type FlashListRef } from "@shopify/flash-list";
import React, { useCallback, useEffect, useMemo, useRef } from "react";
import { ActivityIndicator, RefreshControl, Text, View } from "react-native";
import EmptyMoments from "./EmptyMoments";
import MomentItem from "./MomentItem";

type Props = {
  items: Moment[];
  onRefresh?: () => void;
  refreshing?: boolean;
  onLoadMore?: () => void;
  hasNextPage?: boolean;
  isLoadingMore?: boolean;
};

// FlashList item types
type SectionHeaderItem = {
  type: "header";
  title: string;
};

type MomentPairItem = {
  type: "pair";
  moments: [Moment, Moment?];
};

type FlashListItem = SectionHeaderItem | MomentPairItem;

const SECTIONS_ORDER = [
  "Today",
  "Yesterday",
  "This Week",
  "Week ago",
  "2 Weeks ago",
  "3 Weeks ago",
  "4 Weeks ago",
  "Month ago",
  "2 Months ago",
  "3 Months ago",
  "4 Months ago",
  "5 Months ago",
  "Half a year ago",
];

const chunk2 = <T,>(arr: T[]) => {
  const out: [T, T?][] = [];
  for (let i = 0; i < arr.length; i += 2) out.push([arr[i], arr[i + 1]]);
  return out;
};

// Optimized date calculations with caching
const dateCache = new Map<string, string>();
const todayCache = new Map<string, Date>();

const getCachedToday = (): Date => {
  const todayKey = new Date().toDateString();
  if (!todayCache.has(todayKey)) {
    todayCache.set(todayKey, new Date());
  }
  return todayCache.get(todayKey)!;
};

const getSectionTitle = (date: Date, today: Date): string => {
  const dateKey = date.toDateString();
  const todayKey = today.toDateString();
  const cacheKey = `${dateKey}-${todayKey}`;

  // Check cache first
  if (dateCache.has(cacheKey)) {
    return dateCache.get(cacheKey) as string;
  }

  const yesterday = new Date(today);
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayKey = yesterday.toDateString();

  let sectionTitle: string;

  if (dateKey === todayKey) {
    sectionTitle = "Today";
  } else if (dateKey === yesterdayKey) {
    sectionTitle = "Yesterday";
  } else if (date > new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000)) {
    sectionTitle = "This Week";
  } else {
    // Calculate weeks and months ago - optimized calculations
    const diffTime = today.getTime() - date.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    const diffWeeks = Math.floor(diffDays / 7);
    const diffMonths = Math.floor(diffDays / 30);

    if (diffWeeks === 1) {
      sectionTitle = "Week ago";
    } else if (diffWeeks === 2) {
      sectionTitle = "2 Weeks ago";
    } else if (diffWeeks === 3) {
      sectionTitle = "3 Weeks ago";
    } else if (diffMonths === 1) {
      sectionTitle = "Month ago";
    } else if (diffWeeks === 4) {
      sectionTitle = "4 Weeks ago";
    } else if (diffMonths === 2) {
      sectionTitle = "2 Months ago";
    } else if (diffMonths === 3) {
      sectionTitle = "3 Months ago";
    } else if (diffMonths === 4) {
      sectionTitle = "4 Months ago";
    } else if (diffMonths === 5) {
      sectionTitle = "5 Months ago";
    } else {
      sectionTitle = "Half a year ago";
    }
  }

  // Cache the result
  dateCache.set(cacheKey, sectionTitle);

  // Limit cache size to prevent memory leaks
  if (dateCache.size > 1000) {
    const firstKey = dateCache.keys().next().value;
    if (firstKey) {
      dateCache.delete(firstKey);
    }
  }

  return sectionTitle;
};

const groupMomentsByDate = (moments: Moment[]): FlashListItem[] => {
  if (moments.length === 0) return [];

  const groups: { [key: string]: Moment[] } = {};
  const today = getCachedToday(); // Use cached today

  moments.forEach((moment) => {
    const date = new Date(moment.happenedAt);
    const sectionTitle = getSectionTitle(date, today);

    if (!groups[sectionTitle]) {
      groups[sectionTitle] = [];
    }
    groups[sectionTitle].push(moment);
  });

  // Flatten: mix section headers and moment pairs in one array
  const flatList: FlashListItem[] = [];

  SECTIONS_ORDER.forEach((title) => {
    if (groups[title] && groups[title].length > 0) {
      // Add section header
      flatList.push({ type: "header", title });

      // Sort moments within each section (newest first)
      const sortedMoments = groups[title].sort(
        (a, b) =>
          new Date(b.happenedAt).getTime() - new Date(a.happenedAt).getTime()
      );

      // Chunk into pairs and add to flat list
      const pairs = chunk2(sortedMoments);
      pairs.forEach((pair) => {
        flatList.push({ type: "pair", moments: pair });
      });
    }
  });

  return flatList;
};

type SectionHeaderProps = {
  text: string;
  isSticky?: boolean;
};

const SectionHeader = React.memo(
  ({ text, isSticky = false }: SectionHeaderProps) => {
    return (
      <View
        // className={`px-4 mb-4 ${isSticky ? "bg-gray-900/95 pt-2" : "bg-transparent"}`}
        className="px-4 mb-4 bg-transparent"
      >
        <View
          className={`bg-vitality-500 rounded-lg border border-vitality-300 ${
            isSticky ? "shadow-lg" : ""
          }`}
        >
          <View className="p-2">
            <Text
              style={{ fontFamily: "Comfortaa" }}
              className="text-base font-bold text-white text-center tracking-wide"
            >
              {text}
            </Text>
          </View>
        </View>
      </View>
    );
  }
);

type SectionItemProps = {
  item: [Moment, Moment?];
  highlightedItemId: string | null;
  isInitMomentPanelShown: boolean;
  onLongPress: (item: Moment) => void;
};

const SectionItem = React.memo(
  ({
    item,
    highlightedItemId,
    isInitMomentPanelShown,
    onLongPress,
  }: SectionItemProps) => {
    return (
      <View className="flex-row gap-4 px-6 mb-4">
        <MomentItem
          item={item[0]}
          isHighlighted={item[0].id === highlightedItemId}
          isInitMomentPanelShown={isInitMomentPanelShown}
          onLongPress={onLongPress}
        />
        {item[1] ? (
          <MomentItem
            item={item[1]}
            isHighlighted={item[1].id === highlightedItemId}
            isInitMomentPanelShown={isInitMomentPanelShown}
            onLongPress={onLongPress}
          />
        ) : (
          <View className="flex-1"></View>
        )}
      </View>
    );
  },
  (prevProps, nextProps) => {
    // Only re-render if:
    // 1. The items themselves changed (compare IDs)
    // 2. The highlight state changed for either item in this pair
    // 3. isInitMomentPanelShown changed
    // 4. onLongPress callback changed

    // Check if items changed
    if (prevProps.item[0].id !== nextProps.item[0].id) return false;
    if (prevProps.item[1]?.id !== nextProps.item[1]?.id) return false;

    // Check if highlight state changed for first item
    const prevFirstHighlighted =
      prevProps.item[0].id === prevProps.highlightedItemId;
    const nextFirstHighlighted =
      nextProps.item[0].id === nextProps.highlightedItemId;
    if (prevFirstHighlighted !== nextFirstHighlighted) return false;

    // Check if highlight state changed for second item (if it exists)
    if (prevProps.item[1] && nextProps.item[1]) {
      const prevSecondHighlighted =
        prevProps.item[1].id === prevProps.highlightedItemId;
      const nextSecondHighlighted =
        nextProps.item[1].id === nextProps.highlightedItemId;
      if (prevSecondHighlighted !== nextSecondHighlighted) return false;
    }

    // Check if isInitMomentPanelShown changed
    if (prevProps.isInitMomentPanelShown !== nextProps.isInitMomentPanelShown)
      return false;

    // Check if onLongPress callback changed
    if (prevProps.onLongPress !== nextProps.onLongPress) return false;

    // No relevant changes, skip re-render
    return true;
  }
);

type FooterProps = {
  hasNextPage?: boolean;
  isLoadingMore?: boolean;
};

const Footer = React.memo(({ hasNextPage, isLoadingMore }: FooterProps) => {
  if (!hasNextPage) return null;

  return (
    <View className="pb-8 flex items-center">
      {isLoadingMore ? (
        <View className="flex items-center gap-2">
          <Text
            style={{ fontFamily: "Comfortaa" }}
            className="text-white text-sm"
          >
            Loading more moments...
          </Text>
          <ActivityIndicator size="small" color="#fff" />
        </View>
      ) : (
        <Text
          style={{ fontFamily: "Comfortaa" }}
          className="text-white/70 text-sm"
        >
          Pull to load more
        </Text>
      )}
    </View>
  );
});

const MomentsList = ({
  items,
  onRefresh,
  refreshing = false,
  onLoadMore,
  hasNextPage = false,
  isLoadingMore = false,
}: Props) => {
  const flashListRef = useRef<FlashListRef<FlashListItem>>(null);

  // Store hooks - centralized at parent level
  const highlightedItem = useHighlightedItemStore(
    (state) => state.highlightedItem
  );
  const setHighlightedItem = useHighlightedItemStore(
    (state) => state.setHighlightedItem
  );
  const openModal = useModalStore((state) => state.openModal);
  const isInitMomentPanelShown = useMainPanelStore(
    (state) => state.isInitMomentPanelShown
  );

  const highlightedItemId = highlightedItem?.id;

  // Memoized callback for handling long press
  const handleLongPress = useCallback(
    (item: Moment) => {
      setHighlightedItem(null);
      openModal("moment", item);
    },
    [setHighlightedItem, openModal]
  );

  // Memoize flattened data
  const flatData = useMemo(() => groupMomentsByDate(items), [items]);

  // Calculate sticky header indices
  const stickyHeaderIndices = useMemo(() => {
    return flatData
      .map((item, index) => (item.type === "header" ? index : -1))
      .filter((index) => index !== -1);
  }, [flatData]);

  // Scroll to top when highlighted item changes
  useEffect(() => {
    if (highlightedItem && flashListRef.current && flatData.length > 0) {
      // Use requestAnimationFrame to ensure smooth scrolling
      requestAnimationFrame(() => {
        flashListRef.current?.scrollToIndex({
          index: 0,
          animated: true,
        });
      });
    }
  }, [highlightedItem, flatData]);

  const renderItem = useCallback(
    ({ item, target }: { item: FlashListItem; target?: string }) => {
      if (item.type === "header") {
        return (
          <SectionHeader
            text={item.title}
            isSticky={target === "StickyHeader"}
          />
        );
      }

      return (
        <SectionItem
          item={item.moments}
          highlightedItemId={highlightedItemId ?? null}
          isInitMomentPanelShown={isInitMomentPanelShown}
          onLongPress={handleLongPress}
        />
      );
    },
    [highlightedItemId, isInitMomentPanelShown, handleLongPress]
  );

  const handleEndReached = useCallback(() => {
    if (hasNextPage && !isLoadingMore && onLoadMore) {
      // Use requestAnimationFrame to prevent blocking the UI thread
      requestAnimationFrame(() => {
        onLoadMore();
      });
    }
  }, [hasNextPage, isLoadingMore, onLoadMore]);

  const renderFooter = useCallback(() => {
    return <Footer hasNextPage={hasNextPage} isLoadingMore={isLoadingMore} />;
  }, [hasNextPage, isLoadingMore]);

  const keyExtractor = useCallback((item: FlashListItem, index: number) => {
    if (item.type === "header") {
      return `header-${item.title}`;
    }
    return `${item.moments[0].id}-${item.moments[1]?.id ?? "empty"}`;
  }, []);

  const getItemType = useCallback((item: FlashListItem) => {
    return item.type === "header" ? "sectionHeader" : "row";
  }, []);

  return (
    <View className="flex-1 pt-20 pb-24">
      <FlashList
        ref={flashListRef}
        data={flatData}
        renderItem={renderItem}
        keyExtractor={keyExtractor}
        getItemType={getItemType}
        stickyHeaderIndices={stickyHeaderIndices}
        showsVerticalScrollIndicator={false}
        ListEmptyComponent={EmptyMoments}
        ListFooterComponent={renderFooter}
        refreshControl={
          <RefreshControl
            refreshing={refreshing}
            onRefresh={onRefresh}
            tintColor="#ffb3c6"
            colors={["#ffb3c6"]}
          />
        }
        onEndReached={handleEndReached}
        onEndReachedThreshold={0.3}
        drawDistance={1500}
      />
    </View>
  );
};

export default MomentsList;
