# DriversandMinders - ApoBasi Driver & Bus Minder Application

<div align="center">

**GPS Broadcasting & Attendance Management for School Bus Staff**

[![Flutter](https://img.shields.io/badge/Flutter-3.6.0+-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.6.0+-blue.svg)](https://dart.dev/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey.svg)](https://flutter.dev/)

</div>

---

## Overview

DriversandMinders is a unified cross-platform mobile application built with Flutter for both school bus drivers and bus minders (attendants). Drivers use it to broadcast their GPS location in real-time, while bus minders use it to manage student attendance with offline capability.

### Key Features

**For Drivers:**
- **GPS Broadcasting**: Continuous real-time location transmission via WebSocket
- **View Assigned Bus**: See bus details and specifications
- **Route Information**: View all children on the route with parent contacts
- **Start/End Shift**: Mark shift status for tracking
- **Emergency Contacts**: Quick access to parent phone numbers

**For Bus Minders:**
- **Attendance Management**: Mark students present/absent with offline support
- **Multiple Bus Support**: Manage attendance for multiple assigned buses
- **Status Updates**: Update child status (boarding, at school, dropped off)
- **Offline Mode**: Queue attendance updates when offline, sync when connected
- **Parent Contacts**: View parent information for each child
- **Photo Verification**: Camera integration for attendance verification (optional)

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [User Roles](#user-roles)
- [Features by Role](#features-by-role)
- [API Integration](#api-integration)
- [Real-Time GPS Broadcasting](#real-time-gps-broadcasting)
- [Offline Attendance](#offline-attendance)
- [Configuration](#configuration)
- [Building for Production](#building-for-production)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- **Flutter SDK**: Version 3.6.0 or higher
- **Dart SDK**: Version 3.6.0 or higher
- **Android Studio** or **Xcode** (platform-specific)
- **Backend Server**: ApoBasi Django backend running on port 8000
- **Socket.IO Server**: Real-time server running on port 4000

---

## Installation

### 1. Install Dependencies

```bash
# Navigate to DriversandMinders directory
cd Apo_Basi/DriversandMinders

# Get Flutter packages
flutter pub get
```

### 2. Configure API Endpoints

Edit `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
  static const String socketUrl = 'http://YOUR_LOCAL_IP:4000';
}
```

### 3. Run the App

```bash
# Check connected devices
flutter devices

# Run the app
flutter run
```

---

## Project Structure

```
DriversandMinders/
│
├── lib/
│   ├── main.dart                      # App entry point
│   │
│   ├── screens/
│   │   ├── login_screen.dart          # Unified login for both roles
│   │   ├── driver/
│   │   │   ├── driver_dashboard.dart  # Driver home screen
│   │   │   ├── bus_details_screen.dart
│   │   │   ├── route_screen.dart      # View children on route
│   │   │   └── gps_tracking_screen.dart
│   │   │
│   │   └── busminder/
│   │       ├── minder_dashboard.dart  # Bus minder home screen
│   │       ├── bus_selection_screen.dart
│   │       ├── attendance_screen.dart # Mark attendance
│   │       └── children_list_screen.dart
│   │
│   ├── services/
│   │   ├── api_service.dart           # HTTP client (Dio)
│   │   ├── socket_service.dart        # WebSocket for GPS
│   │   ├── gps_service.dart           # Location tracking
│   │   ├── storage_service.dart       # Local data storage
│   │   └── attendance_sync_service.dart # Offline sync
│   │
│   ├── models/
│   │   ├── user.dart
│   │   ├── bus.dart
│   │   ├── child.dart
│   │   ├── attendance.dart
│   │   └── route.dart
│   │
│   └── widgets/
│       ├── child_attendance_card.dart
│       ├── bus_status_card.dart
│       └── gps_indicator.dart
│
├── android/                           # Android configuration
├── ios/                               # iOS configuration
├── pubspec.yaml                       # Dependencies
└── README.md                          # This file
```

---

## User Roles

This app supports two distinct user roles:

### 1. Driver (`user_type: 'driver'`)
- Broadcasts GPS location continuously
- Views assigned bus and route
- Accesses parent contact information
- Cannot mark attendance

### 2. Bus Minder (`user_type: 'busminder'`)
- Marks student attendance
- Can be assigned to multiple buses
- Offline attendance capability
- Views children on assigned buses
- Cannot broadcast GPS (driver-only feature)

The app automatically detects the user role from the login response and displays the appropriate interface.

---

## Features by Role

### Driver Features

#### 1. GPS Broadcasting

Drivers broadcast their location every 5 seconds:

```dart
// lib/services/gps_service.dart
class GpsService {
  Timer? _locationTimer;

  void startBroadcasting(int busId) {
    _locationTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      Position position = await Geolocator.getCurrentPosition();

      socketService.broadcastLocation(
        busId: busId,
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        heading: position.heading,
      );
    });
  }

  void stopBroadcasting() {
    _locationTimer?.cancel();
  }
}
```

#### 2. View Assigned Bus

```dart
// API: GET /api/drivers/my-bus/
final bus = await apiService.getMyBus();

// Returns:
{
  "id": 1,
  "numberPlate": "UAH 123X",
  "model": "Toyota Coaster",
  "capacity": 40,
  "isActive": true
}
```

#### 3. View Route with Parent Contacts

```dart
// API: GET /api/drivers/my-route/
final route = await apiService.getMyRoute();

// Returns list of children with parent contacts
{
  "bus": {...},
  "route": [
    {
      "childName": "Alice Doe",
      "classGrade": "Grade 5",
      "parentName": "John Doe",
      "parentContact": "+256700123456"
    }
  ]
}
```

### Bus Minder Features

#### 1. View Assigned Buses

Bus minders can be assigned to multiple buses:

```dart
// API: GET /api/busminders/my-buses/
final buses = await apiService.getMyBuses();

// Returns:
{
  "buses": [
    {
      "id": 1,
      "numberPlate": "UAH 123X",
      "capacity": 40,
      "childrenCount": 15
    }
  ]
}
```

#### 2. View Children on Bus

```dart
// API: GET /api/busminders/buses/{bus_id}/children/
final children = await apiService.getChildrenOnBus(busId);

// Returns:
{
  "children": [
    {
      "id": 1,
      "firstName": "Alice",
      "lastName": "Doe",
      "classGrade": "Grade 5",
      "parent": {
        "name": "John Doe",
        "phoneNumber": "+256700123456"
      },
      "todayAttendance": {
        "status": "present",
        "lastUpdated": "2025-11-07T07:15:00Z"
      }
    }
  ]
}
```

#### 3. Mark Attendance (Offline Capable)

```dart
// API: POST /api/busminders/mark-attendance/
Future<void> markAttendance({
  required int childId,
  required String status,
  String? notes,
}) async {
  final attendanceData = {
    'childId': childId,
    'status': status,
    'notes': notes,
    'timestamp': DateTime.now().toIso8601String(),
  };

  try {
    // Try to send immediately
    await apiService.markAttendance(attendanceData);
  } catch (e) {
    // If offline, queue for later
    await attendanceSyncService.queueAttendance(attendanceData);
  }
}
```

**Status Options:**
- `not_on_bus`
- `on_bus`
- `at_school`
- `on_way_home`
- `dropped_off`
- `absent`

---

## API Integration

### Authentication

Both drivers and bus minders login with username/password:

```dart
// POST /api/users/login/
final response = await dio.post('/users/login/', data: {
  'username': username,
  'password': password,
});

// Store tokens
await storage.write('access_token', response.data['access']);
await storage.write('user_type', response.data['user']['userType']);

// Route based on user type
if (response.data['user']['userType'] == 'driver') {
  Navigator.pushReplacement(context, DriverDashboard());
} else if (response.data['user']['userType'] == 'busminder') {
  Navigator.pushReplacement(context, MinderDashboard());
}
```

### Authorization

All API requests include JWT token:

```dart
dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) async {
    final token = await storage.read('access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  },
));
```

---

## Real-Time GPS Broadcasting

### Socket.IO Integration

Drivers broadcast GPS via Socket.IO:

```dart
// lib/services/socket_service.dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketService {
  late IO.Socket socket;

  void connect() {
    socket = IO.io(
      socketUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build()
    );

    socket.connect();

    socket.onConnect((_) {
      print('Connected to Socket.IO server');
    });
  }

  void broadcastLocation({
    required int busId,
    required double latitude,
    required double longitude,
    required double speed,
    required double heading,
  }) {
    socket.emit('driver_location_room', {
      'busId': busId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void disconnect() {
    socket.disconnect();
    socket.dispose();
  }
}
```

### GPS Location Service

```dart
// lib/services/gps_service.dart
import 'package:geolocator/geolocator.dart';

class GpsService {
  Future<bool> checkPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission == LocationPermission.always ||
           permission == LocationPermission.whileInUse;
  }

  Future<Position> getCurrentLocation() async {
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    );
  }
}
```

---

## Offline Attendance

### Queue System

When offline, attendance updates are queued locally:

```dart
// lib/services/attendance_sync_service.dart
class AttendanceSyncService {
  final String _queueKey = 'attendance_queue';

  Future<void> queueAttendance(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Get existing queue
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    // Add new attendance
    queue.add(json.encode(data));

    // Save queue
    await prefs.setStringList(_queueKey, queue);

    // Try to sync immediately
    await syncQueue();
  }

  Future<void> syncQueue() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> queue = prefs.getStringList(_queueKey) ?? [];

    if (queue.isEmpty) return;

    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    List<String> failedItems = [];

    for (String item in queue) {
      try {
        Map<String, dynamic> data = json.decode(item);
        await apiService.markAttendance(data);
      } catch (e) {
        // Keep failed items in queue
        failedItems.add(item);
      }
    }

    // Update queue with only failed items
    await prefs.setStringList(_queueKey, failedItems);
  }
}
```

### Auto-Sync on Connectivity

```dart
// Listen for connectivity changes
Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
  if (result != ConnectivityResult.none) {
    attendanceSyncService.syncQueue();
  }
});
```

---

## Configuration

### Android Permissions

Edit `android/app/src/main/AndroidManifest.xml`:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
    <uses-permission android:name="android.permission.CAMERA" />
</manifest>
```

### iOS Permissions

Edit `ios/Runner/Info.plist`:

```xml
<dict>
    <key>NSLocationWhenInUseUsageDescription</key>
    <string>We need location access to broadcast bus position</string>

    <key>NSLocationAlwaysUsageDescription</key>
    <string>We need location access to track the bus in background</string>

    <key>NSCameraUsageDescription</key>
    <string>We need camera access for attendance verification</string>
</dict>
```

---

## Building for Production

### Android

```bash
# Build APK
flutter build apk --release

# Build App Bundle
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

### GPS Not Broadcasting

**Problem:** Location not updating on parent app.

**Solution:**
```dart
// Check permissions first
final hasPermission = await gpsService.checkPermissions();
if (!hasPermission) {
  await Geolocator.openAppSettings();
}

// Verify Socket.IO connection
print('Socket connected: ${socketService.socket.connected}');
```

### Offline Attendance Not Syncing

**Problem:** Queued attendance not uploading when back online.

**Solution:**
```dart
// Manually trigger sync
await attendanceSyncService.syncQueue();

// Check queue status
final prefs = await SharedPreferences.getInstance();
final queue = prefs.getStringList('attendance_queue');
print('Pending items: ${queue?.length ?? 0}');
```

### Cannot Login

**Problem:** Authentication fails for driver/bus minder.

**Solution:**
```bash
# Verify backend is running
curl http://YOUR_IP:8000/api/users/login/

# Check credentials with admin
# Ensure user_type is 'driver' or 'busminder' in database
```

---

## Testing

```bash
# Run all tests
flutter test

# Test GPS service
flutter test test/services/gps_service_test.dart

# Test offline sync
flutter test test/services/attendance_sync_test.dart
```

---

## Performance Tips

### 1. Battery Optimization

```dart
// Reduce GPS polling frequency when stationary
if (position.speed < 1.0) {
  // Increase interval to 30 seconds
  _locationTimer = Timer.periodic(Duration(seconds: 30), ...);
} else {
  // Normal 5-second interval
  _locationTimer = Timer.periodic(Duration(seconds: 5), ...);
}
```

### 2. Network Optimization

```dart
// Batch attendance updates
List<Map<String, dynamic>> batch = [];
batch.add(attendanceData);

if (batch.length >= 10) {
  await apiService.bulkMarkAttendance(batch);
  batch.clear();
}
```

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/new-feature`
3. Follow Flutter style guide
4. Test both driver and bus minder flows
5. Submit pull request

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

**DriversandMinders - Empowering School Transport Staff**

Built with ❤️ using Flutter

</div>
