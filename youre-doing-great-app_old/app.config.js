export default ({ config }) => {
  // Get environment variables
  const env = process.env.EXPO_PUBLIC_ENV || "development";

  // Determine app name and bundle identifier based on environment
  const appName =
    env === "production" ? "You Are Doing Great" : "You Are Doing Great (Dev)";

  const bundleId = "ee.required.you-are-doing-great";

  return {
    name: appName,
    slug: "you-are-doing-great",
    version: "1.0.0",
    orientation: "portrait",
    icon: "./assets/images/icon.png",
    scheme: "you-are-doing-great",
    userInterfaceStyle: "automatic",
    newArchEnabled: true,
    ios: {
      supportsTablet: true,
      bundleIdentifier: bundleId,
      icon: "./assets/images/icon-dark.png",
      // TODO: Uncomment when this resolved https://github.com/expo/expo/issues/39782
      // icon: {
      //   dark: "./assets/icons/ios-dark.png",
      //   light: "./assets/icons/ios-light.png",
      //   tint: "./assets/icons/ios-tinted.png",
      // },
      infoPlist: {
        ITSAppUsesNonExemptEncryption: false,
      },
    },
    android: {
      adaptiveIcon: {
        foregroundImage: "./assets/images/adaptive-icon.png",
        backgroundColor: "#ffffff",
      },
      edgeToEdgeEnabled: true,
      package: bundleId,
    },
    web: {
      bundler: "metro",
      output: "static",
      favicon: "./assets/images/favicon.png",
    },
    plugins: [
      "expo-router",
      [
        "expo-splash-screen",
        {
          image: "./assets/icons/splash-icon-light.png",
          imageWidth: 200,
          resizeMode: "contain",
          backgroundColor: "#001219",
        },
      ],
      "expo-localization",
      "expo-web-browser",
      [
        "@sentry/react-native/expo",
        {
          url: "https://sentry.io/",
          project: "you-are-doing-great",
          organization: "yara-m",
        },
      ],
    ],
    experiments: {
      typedRoutes: true,
    },
    extra: {
      router: {},
      eas: {
        projectId: "2e5e0aa3-2013-48da-9f27-866e28a6aef7",
      },
    },
  };
};
