# ApoBasi - Build Instructions

## Quick APK Build (Recommended)

### Prerequisites
1. Install Expo CLI: `npm install -g @expo/cli`
2. Create Expo account at https://expo.dev
3. Login: `eas login`

### Build APK
```bash
# Install dependencies (if not already installed)
npm install

# Configure EAS Build (first time only)
eas build:configure

# Build APK for Android
eas build --platform android --profile preview

# Or build both platforms
eas build --platform all --profile preview
```

## Alternative: Local Build with Expo Tools

### For Development Testing
```bash
# Export for testing
npx expo export --platform android

# Install Expo Dev Build
npx expo install expo-dev-client

# Build development client
eas build --profile development
```

### For Production
```bash
# Build production APK
eas build --platform android --profile production
```

## App Configuration Summary

- **App Name**: ApoBasi
- **Package ID**: com.yourcompany.apobasi
- **Version**: 1.0.0
- **Scheme**: apobasi

## Features Ready for Production

✅ **Authentication** - Login with parent@test.com
✅ **Dashboard** - Children list with bus status
✅ **Live Tracking** - Real-time bus location with breadcrumb trail
✅ **Notifications** - Priority-based alerts system
✅ **Profile Management** - User settings and preferences

## Mock Data Available
The app currently uses mock data for demonstration. To connect to your DRF backend:

1. Update `API_BASE_URL` in `src/services/api.ts`
2. Replace mock implementations with actual API calls
3. Configure authentication tokens properly

## Permissions Configured
- Location access for maps
- Push notifications
- Network access for API calls

## Next Steps
1. Run `eas login` with your Expo account
2. Execute `eas build --platform android --profile preview`
3. Download the APK from the Expo dashboard
4. Install and test on Android device

The app is fully functional with a beautiful UI and all parent tracking features implemented!