import { useCurrentUserQuery } from "@/hooks/useCurrentUserQuery";
import { useRevenueCatCustomerInfoQuery } from "@/hooks/useRevenueCatCustomerInfoQuery";

const useUserProfile = () => {
  const { data: user } = useCurrentUserQuery();
  const { data: customerInfo } = useRevenueCatCustomerInfoQuery();
  return {
    user,
    customerInfo,
  };
};

export default useUserProfile;
