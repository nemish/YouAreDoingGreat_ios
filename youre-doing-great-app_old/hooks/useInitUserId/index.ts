import useUserIdStore from "@/hooks/stores/useUserIdStore";
import { useEffect } from "react";
import "react-native-get-random-values";
import * as Keychain from "react-native-keychain";
import { v4 as uuidv4 } from "uuid";
import * as Sentry from "@sentry/react-native";
import logger from "@/utils/logger";

const KEYCHAIN_SERVICE = "ee.required.you-are-doing-great.userid";

type RetryInitUserIdFromKeychainArgs = {
  attempts: number;
  fallbackUserId: string;
};

type SetUserIdToKeychainArgs = {
  userId: string;
};

const setUserIdToKeychain = async ({ userId }: SetUserIdToKeychainArgs) => {
  try {
    await Keychain.setGenericPassword(
      "user_id", // username (required but not used)
      userId,
      {
        service: KEYCHAIN_SERVICE,
        accessible: Keychain.ACCESSIBLE.WHEN_UNLOCKED,
        cloudSync: true, // Enable iCloud Keychain sync across devices
      }
    );
  } catch (error) {
    logger.error("Error with Keychain, setting user ID:", error);
  }
};

const getUserIdFromKeychain = async () => {
  try {
    const credentials = await Keychain.getGenericPassword({
      service: KEYCHAIN_SERVICE,
      cloudSync: true, // Enable iCloud Keychain sync across devices
    });
    return credentials && credentials.password;
  } catch (error) {
    logger.error("Error with Keychain, getting user ID:", error);
    return null;
  }
};

/**
 * Get user ID from iOS Keychain with iCloud synchronization
 * Falls back to generating a new ID if Keychain is unavailable
 */
const useInitUserId = () => {
  const userId = useUserIdStore((state) => state.userId);
  const setUserId = useUserIdStore((state) => state.setUserId);
  useEffect(() => {
    if (userId) {
      return;
    }
    const initUserIdFromKeychain = async () => {
      try {
        // Try to get existing user ID from Keychain
        const userIdFromKeychain = await getUserIdFromKeychain();
        logger.debug("userIdFromKeychain", userIdFromKeychain);

        if (userIdFromKeychain) {
          setUserId(userIdFromKeychain, true);
          Sentry.setUser({ id: userIdFromKeychain });
          return;
        }

        // No existing ID found, generate and store a new one
        const newUserId = uuidv4();
        logger.debug("newUserId", newUserId);

        retryInitUserIdFromKeychain({
          fallbackUserId: newUserId,
          attempts: 0,
        });

        setUserId(newUserId);
        Sentry.setUser({ id: newUserId });
      } catch (error) {
        logger.error("Error with Keychain, generating new user ID:", error);

        // Fallback: generate a new ID even if storage fails
        const newUserId = uuidv4();
        logger.debug("newUserId (fallback)", newUserId);
        setUserId(newUserId);
        Sentry.setUser({ id: newUserId });
      }
    };

    const retryInitUserIdFromKeychain = async ({
      fallbackUserId,
      attempts,
    }: RetryInitUserIdFromKeychainArgs) => {
      const userIdFromKeychain = await getUserIdFromKeychain();
      if (userIdFromKeychain) {
        setUserId(userIdFromKeychain, true);
        Sentry.setUser({ id: userIdFromKeychain });
        return;
      }

      if (attempts > 3) {
        await setUserIdToKeychain({ userId: fallbackUserId });
        setUserId(fallbackUserId, true);
        Sentry.setUser({ id: fallbackUserId });
        return;
      }

      setTimeout(() => {
        retryInitUserIdFromKeychain({
          fallbackUserId,
          attempts: attempts + 1,
        });
      }, 3000);
    };
    initUserIdFromKeychain();
  }, [userId, setUserId]);
};

export default useInitUserId;
