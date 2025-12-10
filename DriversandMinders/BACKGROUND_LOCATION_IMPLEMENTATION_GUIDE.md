# Background Location Tracking Implementation Guide

## Overview

This guide explains how to use the native Android foreground service for continuous background location tracking in the Drivers app.

## What Has Been Implemented

### 1. Native Android Foreground Service ✅

**Location:** `android/app/src/main/kotlin/com/apobasi/driver/`

**Files Created:**
- `LocationTrackingService.kt` - Main foreground service
- `LocationServiceManager.kt` - Service manager utility
- `MainActivity.kt` - Updated with Method Channel

**Features:**
- ✅ Continues tracking when app is minimized
- ✅ Continues tracking when phone is locked
- ✅ Continues tracking when app is swiped away
- ✅ Continues tracking when screen is off
- ✅ Shows persistent notification while tracking
- ✅ Uses FusedLocationProviderClient for accurate GPS
- ✅ Wake lock to prevent service from sleeping
- ✅ START_STICKY to restart if killed by system

### 2. Flutter Services ✅

**Files Created:**
- `lib/services/native_location_service.dart` - Method Channel communication
- `lib/services/trip_state_service.dart` - Trip state persistence

### 3. Socket.IO Notifications ✅

**Enhanced Endpoints:**
- `/api/notify/trip-start` - Notify parents when trip starts
- `/api/notify/child-status` - Notify parents when child status changes (pickup/dropoff)
- `/api/notify/trip-end` - Notify parents when trip ends

## How To Use

### Step 1: Start Trip with Native Service

Update your driver active trip screen to use the native service:

```dart
import '../../services/native_location_service.dart';
import '../../services/trip_state_service.dart';

class DriverActiveTripScreen extends StatefulWidget {
  // ...
}

class _DriverActiveTripScreenState extends State<DriverActiveTripScreen> {
  final NativeLocationService _nativeLocationService = NativeLocationService();
  final TripStateService _tripStateService = TripStateService();

  Future<void> _startTrip() async {
    // Get required data
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final busId = prefs.getInt('bus_id');
    final apiUrl = 'http://YOUR_API_URL:8000'; // Your backend URL

    if (token == null || busId == null) {
      // Handle error
      return;
    }

    // Save trip state for persistence
    await _tripStateService.saveTripState(
      tripId: DateTime.now().millisecondsSinceEpoch,
      tripType: 'morning', // or 'afternoon'
      startTime: DateTime.now(),
      busId: busId,
      busNumber: 'BUS-001', // Get from your bus data
    );

    // Start native foreground service
    final started = await _nativeLocationService.startLocationTracking(
      token: token,
      busId: busId,
      apiUrl: apiUrl,
    );

    if (started) {
      print('✅ Background location service started');
    }
  }

  Future<void> _endTrip() async {
    // Stop the native service
    await _nativeLocationService.stopLocationTracking();

    // Clear trip state
    await _tripStateService.clearTripState();

    // Navigate back
    Navigator.pop(context);
  }
}
```

### Step 2: Check for Active Trip on App Resume

```dart
class _DriverStartShiftScreenState extends State<DriverStartShiftScreen> {
  final TripStateService _tripStateService = TripStateService();
  bool _hasActiveTrip = false;
  Map<String, dynamic>? _activeTripInfo;

  @override
  void initState() {
    super.initState();
    _checkForActiveTrip();
  }

  Future<void> _checkForActiveTrip() async {
    final hasTrip = await _tripStateService.hasActiveTrip();
    final tripInfo = await _tripStateService.getActiveTripInfo();

    setState(() {
      _hasActiveTrip = hasTrip;
      _activeTripInfo = tripInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _hasActiveTrip ? _continueTrip : _startNewTrip,
            child: Text(_hasActiveTrip ? 'Continue Trip' : 'Start Trip'),
          ),
        ],
      ),
    );
  }
}
```

### Step 3: Send Notifications via Socket.IO

```dart
Future<void> notifyTripStart({
  required int busId,
  required String tripType,
  required int tripId,
  required String busNumber,
}) async {
  await dio.post(
    'http://YOUR_SOCKETIO_SERVER:3000/api/notify/trip-start',
    data: {
      'busId': busId,
      'tripType': tripType,
      'tripId': tripId,
      'busNumber': busNumber,
    },
  );
}

Future<void> notifyChildPickup({
  required int busId,
  required int childId,
  required String childName,
  required String status,
  required String busNumber,
}) async {
  await dio.post(
    'http://YOUR_SOCKETIO_SERVER:3000/api/notify/child-status',
    data: {
      'busId': busId,
      'childId': childId,
      'childName': childName,
      'status': status,
      'busNumber': busNumber,
      'timestamp': DateTime.now().toIso8601String(),
    },
  );
}
```

## Testing Checklist

- [ ] App minimized - Location continues
- [ ] Phone locked - Location continues
- [ ] App swiped away - Location continues
- [ ] Screen off - Location continues
- [ ] Start trip, close app, reopen - Shows "Continue Trip"
- [ ] Parents receive trip start notification
- [ ] Parents receive child pickup notification
- [ ] Parents receive trip end notification
