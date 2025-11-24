import { useQuery } from "@tanstack/react-query";
import Purchases from "react-native-purchases";

const normalizePrice = (product: any) => {
  if (product.subscriptionPeriod === "P1M") {
    return product.price * 12;
  }
  return product.price;
};

const getPlans = async () => {
  try {
    const offerings = await Purchases.getOfferings();
    const plans = offerings.current?.availablePackages
      .sort(
        (a, b) =>
          normalizePrice(b.product.price) - normalizePrice(a.product.price)
      )
      .map(({ product }) => ({
        value: product.identifier.toLowerCase(),
        label: product.subscriptionPeriod === "P1M" ? "Monthly" : "Yearly",
        priceDisplay: `${product.priceString}/${
          product.subscriptionPeriod === "P1M" ? "month" : "year"
        }`,
        price: product.price,
        subscriptionPeriod: product.subscriptionPeriod,
      }));
    return plans;
  } catch (error) {
    console.error("Error getting offerings:", error);
    return [];
  }
};

const usePlans = () => {
  return useQuery({
    queryKey: ["plans"],
    queryFn: () => getPlans(),
    // Plans are very stable data (rarely change)
    staleTime: 60 * 60 * 1000, // 1 hour - plans rarely change
    gcTime: 24 * 60 * 60 * 1000, // 24 hours - keep in cache for a full day
  });
};

export default usePlans;
