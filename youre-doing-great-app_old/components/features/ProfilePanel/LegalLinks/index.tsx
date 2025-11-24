import CommonText from "@/components/ui/CommonText";
import LinkWithDescription from "@/components/ui/LinkWithDescription";
import React from "react";
import { View } from "react-native";

const LegalLinks = React.memo(() => {
  return (
    <View className="p-4">
      <CommonText className="mb-4 text-xl font-bold text-white">
        Legal
      </CommonText>

      <View className="space-y-3">
        <LinkWithDescription
          url="https://you-are-doing-great.com/privacy"
          text="Privacy Policy"
          description="How we collect and use your data"
        />

        <LinkWithDescription
          url="https://you-are-doing-great.com/terms"
          text="Terms of Service"
          description="Terms and conditions for using our app"
        />
      </View>
    </View>
  );
});

LegalLinks.displayName = "LegalLinks";

export default LegalLinks;
