import useUserIdStore from "@/hooks/stores/useUserIdStore";
import { useQuery } from "@tanstack/react-query";
import Purchases, { CustomerInfo } from "react-native-purchases";

const getQueryFn =
  (userId: string) => async (): Promise<CustomerInfo | null> => {
    try {
      // return await Purchases.getCustomerInfo();
      const { customerInfo, created } = await Purchases.logIn(userId);
      console.log("Purchases.logIn created", created);
      return customerInfo;
    } catch (e) {
      console.error("Error fetching customer info:", e);
      return null;
    }
  };

export const useRevenueCatCustomerInfoQuery = () => {
  const userId = useUserIdStore((state) => state.userId);
  const queryFn = getQueryFn(userId || "");
  return useQuery<CustomerInfo | null>({
    queryKey: ["revenueCatCustomerInfo", userId],
    queryFn,
    enabled: !!userId, // Only run query when userId is available
    // Subscription status is relatively stable
    staleTime: 10 * 60 * 1000, // 10 minutes - subscription status changes infrequently
    gcTime: 30 * 60 * 1000, // 30 minutes - keep in cache for half an hour
  });
};
