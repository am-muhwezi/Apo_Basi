# Development Setup Guide

## Setting up the Development Environment

### 1. Install Flutter SDK

Download and install Flutter from: https://flutter.dev/docs/get-started/install

### 2. Verify Installation

```bash
flutter doctor
```

### 3. IDE Setup

#### VS Code Extensions
- Flutter
- Dart
- Bracket Pair Colorizer
- Flutter Widget Snippets
- Awesome Flutter Snippets

#### Android Studio Plugins
- Flutter
- Dart

### 4. Dependencies Installation

```bash
cd Apo_Basi
flutter pub get
```

### 5. Running the App

#### Debug Mode
```bash
flutter run
```

#### Release Mode
```bash
flutter run --release
```

### 6. Code Generation

Some files require code generation. Run:

```bash
flutter packages pub run build_runner build
```

### 7. Testing

#### Unit Tests
```bash
flutter test
```

#### Integration Tests
```bash
flutter drive --target=test_driver/app.dart
```

## Firebase Setup

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project
3. Enable Authentication, Firestore, and Cloud Messaging

### 2. Android Configuration
1. Add Android app to Firebase project
2. Download `google-services.json`
3. Place in `android/app/` directory

### 3. iOS Configuration
1. Add iOS app to Firebase project
2. Download `GoogleService-Info.plist`
3. Place in `ios/Runner/` directory

## Google Maps Setup

### 1. Get API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Enable Maps SDK for Android/iOS
3. Create API key

### 2. Android Configuration
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY_HERE"/>
```

### 3. iOS Configuration
Add to `ios/Runner/AppDelegate.swift`:
```swift
GMSServices.provideAPIKey("YOUR_API_KEY_HERE")
```

## Deployment

### Android Release
```bash
flutter build appbundle --release
```

### iOS Release
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Gradle Build Failed**
   - Clean project: `flutter clean`
   - Get dependencies: `flutter pub get`

2. **iOS Build Issues**
   - Update CocoaPods: `pod update`
   - Clean iOS build: `flutter clean`

3. **Maps Not Loading**
   - Check API key configuration
   - Verify API key permissions
   - Check internet connectivity

## Environment Variables

Create `.env` files for different environments:

### `.env.development`
```
API_BASE_URL=https://dev-api.apobasi.com
WS_URL=wss://dev-api.apobasi.com/ws
GOOGLE_MAPS_API_KEY=your_dev_api_key
```

### `.env.production`
```
API_BASE_URL=https://api.apobasi.com
WS_URL=wss://api.apobasi.com/ws
GOOGLE_MAPS_API_KEY=your_prod_api_key
```