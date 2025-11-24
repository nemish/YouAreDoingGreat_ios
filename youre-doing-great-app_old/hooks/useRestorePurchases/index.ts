import { useMutation, useQueryClient } from "@tanstack/react-query";
import Purchases from "react-native-purchases";
import useUserIdStore from "../stores/useUserIdStore";

type RestorePurchasesResult = {
  success: boolean;
  message: string;
};

const restorePurchases = async (): Promise<RestorePurchasesResult> => {
  try {
    const customerInfo = await Purchases.restorePurchases();

    // Check if user has any active entitlements
    const hasActiveEntitlements =
      Object.keys(customerInfo.entitlements.active).length > 0;

    if (hasActiveEntitlements) {
      return {
        success: true,
        message: "Purchases restored successfully!",
      };
    } else {
      return {
        success: false,
        message: "No previous purchases found to restore.",
      };
    }
  } catch (error) {
    console.error("Error restoring purchases:", error);
    return {
      success: false,
      message: "Failed to restore purchases. Please try again.",
    };
  }
};

export const useRestorePurchases = () => {
  const queryClient = useQueryClient();
  const userId = useUserIdStore((state) => state.userId);

  return useMutation({
    mutationFn: restorePurchases,
    onSuccess: (result) => {
      // Invalidate and refetch customer info to update the UI
      queryClient.invalidateQueries({
        queryKey: ["revenueCatCustomerInfo", userId],
      });
      queryClient.invalidateQueries({ queryKey: ["userProfile"] });

      // You might want to show a toast notification here
      console.log(result.message);
    },
    onError: (error) => {
      console.error("Restore purchases error:", error);
    },
  });
};
