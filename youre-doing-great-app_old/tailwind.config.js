/** @type {import('tailwindcss').Config} */
module.exports = {
  // NOTE: Update this to include the paths to all of your component files.
  content: ["./app/**/*.{js,jsx,ts,tsx}", "./components/**/*.{js,jsx,ts,tsx}"],
  presets: [require("nativewind/preset")],
  theme: {
    extend: {
      colors: {
        vitality: {
          50: "#ffe5ec",
          100: "#ffb3c6",
          200: "#ff80a1",
          300: "#ff4d7a",
          400: "#ff265c",
          500: "#ff3366", // main
          600: "#e62e5c",
          700: "#cc2851",
          800: "#b32246",
          900: "#991f3e", // deep
        },
        sunset: {
          50: "#FFF0EE",
          100: "#FFDAD6",
          200: "#FFB4AD",
          300: "#FF8E84",
          400: "#FF685B",
          500: "#FF7A6E", // main
          600: "#E67163",
          700: "#CC6859",
          800: "#B35E4E",
          900: "#995543", // deep
        },
        ocean: {
          50: "#F0F9FF",
          100: "#E0F2FE",
          200: "#BAE6FD",
          300: "#7DD3FC",
          400: "#38BDF8",
          500: "#0EA5E9", // main
          600: "#0284C7",
          700: "#0369A1",
          800: "#075985",
          900: "#0C4A6E", // deep
        },
      },
    },
  },
  plugins: [],
};
