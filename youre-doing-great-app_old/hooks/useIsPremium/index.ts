import useUserProfile from "@/hooks/useUserProfile";

const PREMIUM_ENTITLEMENT_IDENTIFIER = "Premium";
const useIsPremium = () => {
  const { customerInfo } = useUserProfile();
  const isPremium =
    customerInfo?.entitlements.active[PREMIUM_ENTITLEMENT_IDENTIFIER]
      ?.isActive ?? false;
  // const isPremium = true;
  return isPremium;
};

export default useIsPremium;
