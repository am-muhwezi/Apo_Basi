# ParentsApp - ApoBasi Parent Mobile Application

<div align="center">

**Real-Time School Bus Tracking for Parents**

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.6.0+-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)](https://flutter.dev/)

</div>

---

## Overview

ParentsApp is a cross-platform mobile application built with Flutter that enables parents and guardians to track their children's school bus in real-time, view attendance records, and stay informed about their child's transportation status throughout the day.

### Key Features

- **Real-Time GPS Tracking**: Live bus location updates via WebSocket
- **Multiple Children Support**: Track all your children from one account
- **Attendance History**: View detailed pickup and dropoff records
- **Status Updates**: See current status (on bus, at school, dropped off, etc.)
- **Offline Capable**: Cache data locally for offline viewing
- **Push Notifications**: Receive alerts for important events (coming soon)
- **Parent Contact**: Quick access to emergency contacts
- **Responsive Design**: Optimized for all screen sizes

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Architecture](#architecture)
- [Features in Detail](#features-in-detail)
- [API Integration](#api-integration)
- [Configuration](#configuration)
- [Building for Production](#building-for-production)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK**: Version 3.6.0 or higher
- **Dart SDK**: Version 3.6.0 or higher
- **Android Studio** (for Android development)
  - Android SDK
  - Android Emulator
- **Xcode** (for iOS development, macOS only)
  - iOS Simulator
  - CocoaPods
- **Git**: For version control
- **Backend Server**: ApoBasi Django backend running

---

## Installation

### 1. Install Flutter

```bash
# Download Flutter SDK
# Visit: https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor
```

### 2. Install Dependencies

```bash
# Navigate to ParentsApp directory
cd Apo_Basi/ParentsApp

# Get Flutter packages
flutter pub get
```

### 3. Configure API Endpoints

Edit `lib/services/api_service.dart` and update the base URLs:

```dart
class ApiService {
  // Replace with your local IP or production URL
  static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
  static const String socketUrl = 'http://YOUR_LOCAL_IP:4000';

  // For production:
  // static const String baseUrl = 'https://api.apobasi.com/api';
  // static const String socketUrl = 'https://socket.apobasi.com';
}
```

**Important:** When testing on physical devices, use your computer's local IP address, not `localhost`.

### 4. Run the App

```bash
# Check connected devices
flutter devices

# Run on connected device/emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode (optimized)
flutter run --release
```

---

## Project Structure

```
ParentsApp/
│
├── lib/
│   ├── main.dart              # App entry point
│   │
│   ├── screens/               # UI Screens
│   │   ├── login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── tracking_screen.dart
│   │   ├── attendance_screen.dart
│   │   └── profile_screen.dart
│   │
│   ├── services/              # API and business logic
│   │   ├── api_service.dart
│   │   └── storage_service.dart
│   │
│   ├── models/                # Data models
│   │   ├── child.dart
│   │   ├── bus.dart
│   │   └── attendance.dart
│   │
│   └── widgets/               # Reusable components
│
├── assets/                    # Static assets
│   └── images/
│
├── android/                   # Android configuration
├── ios/                       # iOS configuration
└── pubspec.yaml               # Dependencies
```

---

## Architecture

### State Management
Currently using **setState** for local state management.

### Data Flow

#### Authentication Flow
```
LoginScreen → ApiService.login() → Store JWT → DashboardScreen
```

#### Real-Time Tracking Flow
```
TrackingScreen → SocketService.connect() → Listen to bus_update → Update UI
```

---

## Features in Detail

### 1. Phone-Based Login

Parents log in using their registered phone number.

### 2. Dashboard with All Children

View all children with:
- Current status
- Assigned bus information
- Quick access to tracking

### 3. Real-Time GPS Tracking

Live bus location using:
- `google_maps_flutter: ^2.12.3`
- `flutter_map: ^8.2.2` (alternative)
- Socket.IO for live updates

### 4. Attendance History

View detailed records:
- Date
- Status (present/absent)
- Pickup/dropoff times
- Notes

### 5. Status Updates

| Status | Description | Color |
|--------|-------------|-------|
| `not_on_bus` | Child hasn't boarded | Gray |
| `on_bus` | On the bus | Blue |
| `at_school` | Arrived at school | Green |
| `on_way_home` | Heading home | Orange |
| `dropped_off` | Safely dropped off | Green |
| `absent` | Marked absent | Red |

---

## API Integration

### HTTP Client (Dio)

```dart
final response = await dio.post(
  '/parents/direct-phone-login/',
  data: {'phoneNumber': phoneNumber},
);
```

### Local Storage

```dart
import 'package:shared_preferences/shared_preferences.dart';

// Store token
await prefs.setString('access_token', token);

// Retrieve token
final token = prefs.getString('access_token');
```

---

## Configuration

### Android Permissions

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

### iOS Permissions

Edit `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show bus location</string>
```

---

## Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle (Google Play)
flutter build appbundle --release
```

### iOS

```bash
# Build for iOS
flutter build ios --release

# Archive via Xcode
open ios/Runner.xcworkspace
```

---

## Troubleshooting

### Cannot Connect to Backend

```dart
// Use your computer's local IP, not localhost
// Windows: ipconfig
// macOS/Linux: ifconfig

static const String baseUrl = 'http://192.168.1.100:8000/api';
```

### Map Not Displaying

```bash
# Add Google Maps API key

# Android: android/app/src/main/AndroidManifest.xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>

# iOS: ios/Runner/AppDelegate.swift
GMSServices.provideAPIKey("YOUR_API_KEY")
```

### Hot Reload Not Working

```bash
flutter clean
flutter pub get
flutter run
```

---

## Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

---

## Performance Optimization

### Image Caching

```dart
import 'package:cached_network_image/cached_network_image.dart';

CachedNetworkImage(
  imageUrl: child.photoUrl,
  placeholder: (context, url) => CircularProgressIndicator(),
)
```

### List Optimization

```dart
// Use ListView.builder for large lists
ListView.builder(
  itemCount: children.length,
  itemBuilder: (context, index) {
    return ChildCard(child: children[index]);
  },
)
```

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Follow Flutter style guide
4. Run `flutter analyze`
5. Format code: `flutter format .`
6. Submit pull request

---

## License

MIT License - Part of the ApoBasi platform

---

## Support

- GitHub Issues
- Email: support@apobasi.com
- Docs: [docs.apobasi.com](https://docs.apobasi.com)

---

<div align="center">

**ParentsApp - Keeping Parents Connected**

Built with ❤️ using Flutter

</div>
