import ProfilePanel from "@/components/features/ProfilePanel";
import { LinearGradient } from "expo-linear-gradient";
import React from "react";
import { ImageBackground, StyleSheet, View } from "react-native";

const bgPattern = require("@/assets/images/bg-pattern-1-big.jpg");
// const bgPattern = require("@/assets/images/pexels-adrien-olichon-1257089-3137078.jpg");
// const bgPattern = require("@/assets/images/pexels-diva-32862503.jpg");
// const bgPattern = require("@/assets/images/pexels-eva-bronzini-7605539.jpg");

const Profile = () => {
  return (
    <View style={styles.fullScreenAbsolute} className="flex">
      <ImageBackground
        source={bgPattern}
        resizeMode="cover"
        style={[StyleSheet.absoluteFill]}
        imageStyle={[styles.patternImage]}
        fadeDuration={0}
      >
        <LinearGradient
          colors={["#0d1b2a", "#1b263b"]}
          start={{ x: 0.5, y: 0 }}
          end={{ x: 0.5, y: 0.5 }}
          style={[StyleSheet.absoluteFill, { opacity: 0.8 }]}
        />
      </ImageBackground>
      <ProfilePanel />
    </View>
  );
};

const styles = StyleSheet.create({
  fullScreenAbsolute: {
    position: "absolute",
    top: 0,
    bottom: 0,
    left: 0,
    right: 0,
    width: "100%",
  },
  patternImage: {
    opacity: 0.4, // subtle overlay opacity applied to image only
  },
});

export default Profile;
