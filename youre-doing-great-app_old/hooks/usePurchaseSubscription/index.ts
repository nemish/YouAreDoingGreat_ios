import useUserIdStore from "@/hooks/stores/useUserIdStore";
import { useMutation, useQueryClient } from "@tanstack/react-query";
import { Alert } from "react-native";
import Purchases, { CustomerInfo } from "react-native-purchases";

type PurchaseSubscriptionRequest = {
  plan: string;
};

type PurchaseSubscriptionResult = {
  success: boolean;
  customerInfo: CustomerInfo | null;
  message: string;
};

const purchaseSubscription = async ({
  plan,
}: PurchaseSubscriptionRequest): Promise<PurchaseSubscriptionResult> => {
  try {
    // Get available offerings
    const offerings = await Purchases.getOfferings();

    if (!offerings.current) {
      return {
        success: false,
        customerInfo: null,
        message: "No offerings available",
      };
    }

    // Find the package for the selected plan
    const packageToPurchase = offerings.current.availablePackages.find(
      (pkg) => pkg.product.identifier.toLowerCase() === plan.toLowerCase()
    );

    if (!packageToPurchase) {
      return {
        success: false,
        customerInfo: null,
        message: "Selected plan not available",
      };
    }

    // Make the purchase using the package
    const { customerInfo } = await Purchases.purchasePackage(packageToPurchase);

    // Check if user has premium entitlement
    const hasPremium = customerInfo.entitlements.active.premium !== undefined;

    if (hasPremium) {
      return {
        success: true,
        customerInfo,
        message: "Subscription activated successfully!",
      };
    } else {
      return {
        success: false,
        customerInfo,
        message:
          "Purchase completed but premium access not granted. Please contact support.",
      };
    }
  } catch (error) {
    console.error("Purchase error:", error);

    // Handle specific RevenueCat errors
    if (error && typeof error === "object" && "code" in error) {
      switch (error.code) {
        case "PURCHASE_CANCELLED_ERROR":
          return {
            success: false,
            customerInfo: null,
            message: "Purchase was cancelled",
          };
        case "PRODUCT_NOT_AVAILABLE_FOR_PURCHASE_ERROR":
          return {
            success: false,
            customerInfo: null,
            message: "Product not available for purchase",
          };
        case "NETWORK_ERROR":
          return {
            success: false,
            customerInfo: null,
            message:
              "Network error. Please check your connection and try again.",
          };
        case "STORE_PROBLEM_ERROR":
          return {
            success: false,
            customerInfo: null,
            message: "Store problem. Please try again later.",
          };
        default:
          return {
            success: false,
            customerInfo: null,
            message:
              (error as any).message || "Purchase failed. Please try again.",
          };
      }
    }

    // Handle generic errors
    return {
      success: false,
      customerInfo: null,
      message: "An unexpected error occurred. Please try again.",
    };
  }
};

export const usePurchaseSubscription = () => {
  const queryClient = useQueryClient();
  const userId = useUserIdStore((state) => state.userId);

  return useMutation({
    mutationFn: purchaseSubscription,
    onSuccess: (result) => {
      if (result.success) {
        // Invalidate and refetch customer info to update the UI
        queryClient.invalidateQueries({
          queryKey: ["revenueCatCustomerInfo", userId],
        });
        queryClient.invalidateQueries({ queryKey: ["userProfile"] });

        Alert.alert("Success", result.message);
      } else {
        Alert.alert("Purchase Failed", result.message);
      }
    },
    onError: (error) => {
      Alert.alert(
        "Error",
        "An unexpected error occurred during purchase. Please try again."
      );
    },
  });
};
