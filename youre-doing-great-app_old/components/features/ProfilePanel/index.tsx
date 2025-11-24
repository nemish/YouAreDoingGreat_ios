import CommonText from "@/components/ui/CommonText";
import React from "react";
import { ScrollView, View } from "react-native";
import AccountInformation from "./AccountInformation";
import ContactUs from "./ContactUs";
import CurrentPlan from "./CurrentPlan";
import LegalLinks from "./LegalLinks";
import RevenueCatDebugPanel from "./RevenueCatDebugPanel";

const ProfilePanel = () => {
  return (
    <View className="flex-1 flex pt-20 pb-28">
      <ScrollView
        className="flex-1 px-6"
        contentContainerStyle={{ paddingBottom: 20 }}
        showsVerticalScrollIndicator={false}
      >
        <View className="flex-1 gap-8">
          {/* Header */}
          <CommonText className="text-center text-3xl font-bold text-white">
            Profile
          </CommonText>

          <AccountInformation />
          <CurrentPlan />
          <RevenueCatDebugPanel />
          <LegalLinks />
          <ContactUs />

          {/* Contact Us Section */}
        </View>
      </ScrollView>
    </View>
  );
};

export default ProfilePanel;
