import { ErrorBoundary } from "@/components/ErrorBoundary";
import useUserIdStore from "@/hooks/stores/useUserIdStore";
import useInitUserId from "@/hooks/useInitUserId";
import useRevenueCat from "@/hooks/useRevenueCat";
import type { Theme } from "@react-navigation/native";
import { DarkTheme, ThemeProvider } from "@react-navigation/native";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { useFonts } from "expo-font";
import { Stack } from "expo-router";
import * as SplashScreen from "expo-splash-screen";
import { StatusBar } from "expo-status-bar";
import { useEffect, useState } from "react";
import { GestureHandlerRootView } from "react-native-gesture-handler";
import "react-native-reanimated";
import "../global.css";

// import { useColorScheme } from "@/hooks/useColorScheme";
import * as Sentry from "@sentry/react-native";

Sentry.init({
  dsn: process.env.EXPO_PUBLIC_SENTRY_DSN,
  environment: process.env.EXPO_PUBLIC_ENV,

  // Adds more context data to events (IP address, cookies, user, etc.)
  // For more information, visit: https://docs.sentry.io/platforms/react-native/data-management/data-collected/
  sendDefaultPii: true,

  // Enable Logs
  enableLogs: true,

  // Configure Session Replay
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1,
  integrations: [Sentry.mobileReplayIntegration()],

  // uncomment the line below to enable Spotlight (https://spotlightjs.com)
  // spotlight: __DEV__,
});
SplashScreen.preventAutoHideAsync();

SplashScreen.setOptions({
  fade: true,
  duration: 1000,
});

const theme: Theme = {
  ...DarkTheme,
  colors: {
    primary: "rgb(130, 170, 255)", // мягкий светло-голубой — спокойный, не кричит
    background: "rgb(18, 20, 24)", // не true black, а “ночь с огоньком”
    card: "rgb(28, 30, 36)", // чуть светлее, подходит для модальных окон и блоков
    text: "rgb(225, 225, 230)", // нейтральный светлый серый — не режет, но видно
    border: "rgb(60, 63, 70)", // мягкий бордер, не вылазит на первый план
    notification: "rgb(255, 159, 100)", // не агрессивно-красный, а “тёплый пуш” (персик/оранж)
  },
};

const queryClient = new QueryClient();

export default Sentry.wrap(function RootLayout() {
  // const colorScheme = useColorScheme();
  const [appIsReady, setAppIsReady] = useState(false);
  const [fontsLoaded] = useFonts({
    SpaceMono: require("../assets/fonts/SpaceMono-Regular.ttf"),
    Comfortaa: require("../assets/fonts/Comfortaa-VariableFont_wght.ttf"),
    Nunito: require("../assets/fonts/Nunito-VariableFont_wght.ttf"),
    Inter: require("../assets/fonts/Inter-VariableFont_wght.ttf"),
    PatrickHand: require("../assets/fonts/PatrickHand-Regular.ttf"),
  });
  const userId = useUserIdStore((state) => state.userId);
  useInitUserId();
  useRevenueCat();

  useEffect(() => {
    if (!fontsLoaded || !userId) {
      return;
    }
    const prepare = async () => {
      await new Promise((resolve) => setTimeout(resolve, 300));
      setAppIsReady(true);
    };
    prepare();
  }, [fontsLoaded, userId]);

  useEffect(() => {
    if (appIsReady) {
      SplashScreen.hideAsync();
    }
  }, [appIsReady]);

  if (!appIsReady) {
    // Async font loading only occurs in development.
    return null;
  }

  return (
    <ErrorBoundary>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider value={theme}>
          <GestureHandlerRootView>
            <Stack
              screenOptions={{
                headerStyle: {
                  backgroundColor: "#f4511e",
                },
                headerTintColor: "#fff",
                headerTitleStyle: {
                  fontWeight: "bold",
                },
                animation: "fade",
                animationDuration: 300,
              }}
            >
              <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
              <Stack.Screen name="+not-found" />
            </Stack>
          </GestureHandlerRootView>
          <StatusBar style="light" />
        </ThemeProvider>
      </QueryClientProvider>
    </ErrorBoundary>
  );
});
