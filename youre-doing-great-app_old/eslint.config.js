// https://docs.expo.dev/guides/using-eslint/
const { defineConfig } = require("eslint/config");
const expoConfig = require("eslint-config-expo/flat");

module.exports = defineConfig([
  expoConfig,
  {
    ignores: ["dist/*"],
  },
  {
    rules: {
      // Enforce types over interfaces
      "@typescript-eslint/consistent-type-definitions": ["error", "type"],
      // Prevent interface usage
      "@typescript-eslint/no-empty-interface": "error",
      // Prefer type imports
      "@typescript-eslint/consistent-type-imports": "error",
    },
  },
]);
