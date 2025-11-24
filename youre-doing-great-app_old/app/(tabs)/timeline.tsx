import TimelinePanel from "@/components/features/TimelinePanel";
import { LinearGradient } from "expo-linear-gradient";
import React from "react";
import { ImageBackground, StyleSheet, View } from "react-native";

const bgPattern = require("@/assets/images/bg-pattern-1-big.jpg");

const Timeline = () => {
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
      <TimelinePanel />
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
    opacity: 0.4,
  },
});

export default Timeline;
