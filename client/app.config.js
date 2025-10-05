const variant = process.env.APP_VARIANT || 'driver';
const appName = process.env.APP_NAME || 'ApoBasi Driver';

const getPackageIdentifier = (variant) => {
  switch (variant) {
    case 'driver':
      return 'com.apobasi.driver';
    case 'busminder':
      return 'com.apobasi.busminder';
    default:
      return 'com.apobasi.app';
  }
};

const getAppName = (variant) => {
  switch (variant) {
    case 'driver':
      return 'ApoBasi Driver';
    case 'busminder':
      return 'ApoBasi BusMinder';
    default:
      return 'ApoBasi';
  }
};

export default {
  expo: {
    name: process.env.APP_NAME || getAppName(variant),
    slug: "apobasi",
    version: "1.0.0",
    orientation: "portrait",
    icon: "./assets/icon.png",
    userInterfaceStyle: "light",
    scheme: "apobasi",
    newArchEnabled: true,
    splash: {
      image: "./assets/splash.png",
      resizeMode: "contain",
      backgroundColor: "#007AFF"
    },
    assetBundlePatterns: ["**/*"],
    ios: {
      supportsTablet: true,
      bundleIdentifier: getPackageIdentifier(variant),
      buildNumber: "1.0.0",
      infoPlist: {
        NSLocationWhenInUseUsageDescription: "This app needs access to location to show bus locations on the map.",
        NSLocationAlwaysAndWhenInUseUsageDescription: "This app needs access to location to show bus locations on the map.",
        ITSAppUsesNonExemptEncryption: false
      }
    },
    android: {
      adaptiveIcon: {
        foregroundImage: "./assets/adaptive_icon.png",
        backgroundColor: "#007AFF"
      },
      package: getPackageIdentifier(variant),
      versionCode: 1,
      permissions: [
        "ACCESS_FINE_LOCATION",
        "ACCESS_COARSE_LOCATION",
        "RECEIVE_BOOT_COMPLETED",
        "VIBRATE",
        "android.permission.ACCESS_COARSE_LOCATION",
        "android.permission.ACCESS_FINE_LOCATION"
      ]
    },
    web: {
      bundler: "metro",
      output: "static",
      favicon: "./assets/favicon.png"
    },
    plugins: [
      "expo-router",
      [
        "expo-location",
        {
          locationAlwaysAndWhenInUsePermission:
            "Allow $(PRODUCT_NAME) to use your location to show bus locations on the map."
        }
      ],
      [
        "expo-notifications",
        {
          icon: "./assets/notification_icon.png",
          color: "#AA7AFF",
          sounds: ["./assets/notification_sound.wav"]
        }
      ]
    ],
    experiments: {
      typedRoutes: true
    },
    extra: {
      router: {},
      appVariant: variant,
      eas: {
        projectId: "9d8ea2ca-eb2c-4111-af63-b8fc0bae5f16"
      }
    },
    runtimeVersion: {
      policy: "appVersion"
    }
  }
};
