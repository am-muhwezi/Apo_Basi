# Mobile Apps Development Guide (Flutter)
## For Parents, Drivers & Bus Minders Apps

**Target Audience:** Junior developers with NO mobile development background
**Goal:** Take you from zero to developing features and teaching others
**Stack:** Flutter, Dart, REST API integration

---

## Table of Contents
1. [Understanding Mobile Development Basics](#1-understanding-mobile-development-basics)
2. [Flutter Fundamentals](#2-flutter-fundamentals)
3. [Project Structure & Architecture](#3-project-structure--architecture)
4. [Working with REST APIs](#4-working-with-rest-apis)
5. [Building UI Components](#5-building-ui-components)
6. [State Management](#6-state-management)
7. [Navigation & Routing](#7-navigation--routing)
8. [Real-time Location Tracking](#8-real-time-location-tracking)
9. [Local Data Storage](#9-local-data-storage)
10. [Testing & Debugging](#10-testing--debugging)
11. [Common Development Tasks](#11-common-development-tasks)
12. [Best Practices](#12-best-practices)

---

## 1. Understanding Mobile Development Basics

### What is Mobile Development?
Mobile development is creating applications that run on smartphones and tablets. Unlike web apps that run in browsers, mobile apps are installed directly on devices.

### Native vs Cross-Platform
- **Native:** Write separate code for iOS (Swift) and Android (Kotlin/Java)
- **Cross-Platform (Flutter):** Write once, run on both iOS and Android

### Why Flutter?
- Single codebase for iOS & Android
- Fast development with "Hot Reload"
- Beautiful, customizable UI
- Strong community support

---

## 2. Flutter Fundamentals

### 2.1 Installation & Setup

**Install Flutter:**
```bash
# Download Flutter SDK
# https://docs.flutter.dev/get-started/install

# Add to PATH (Linux/Mac)
export PATH="$PATH:`pwd`/flutter/bin"

# Verify installation
flutter doctor
```

**Install IDE:**
- VS Code (Recommended for beginners): https://code.visualstudio.com/
- Install Flutter & Dart extensions

**Setup Emulator:**
```bash
# Android Studio for Android emulator
# Xcode for iOS simulator (Mac only)

# List available devices
flutter devices

# Run app
flutter run
```

### 2.2 Dart Language Basics

Dart is the programming language used by Flutter.

```dart
// Variables
String name = "John";
int age = 25;
double height = 5.9;
bool isActive = true;

// Lists (Arrays)
List<String> names = ['Alice', 'Bob', 'Charlie'];

// Maps (Objects/Dictionaries)
Map<String, dynamic> user = {
  'name': 'John',
  'age': 25,
  'isActive': true,
};

// Functions
String greet(String name) {
  return 'Hello, $name!';
}

// Arrow functions (short syntax)
String greet2(String name) => 'Hello, $name!';

// Classes
class Person {
  String name;
  int age;

  Person(this.name, this.age);

  void introduce() {
    print('I am $name, $age years old');
  }
}

// Using classes
Person person = Person('John', 25);
person.introduce();

// Async/Await (for API calls)
Future<String> fetchData() async {
  await Future.delayed(Duration(seconds: 2));
  return 'Data loaded';
}

// Using async functions
void loadData() async {
  String data = await fetchData();
  print(data);
}
```

### 2.3 Flutter Widgets

**Everything in Flutter is a Widget!**

```dart
import 'package:flutter/material.dart';

// Stateless Widget (doesn't change)
class MyButton extends StatelessWidget {
  final String text;

  const MyButton({required this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        print('Button clicked!');
      },
      child: Text(text),
    );
  }
}

// Stateful Widget (can change over time)
class Counter extends StatefulWidget {
  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  int count = 0;

  void increment() {
    setState(() {
      count++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Count: $count'),
        ElevatedButton(
          onPressed: increment,
          child: Text('Increment'),
        ),
      ],
    );
  }
}
```

**Common Widgets:**
- `Text` - Display text
- `Container` - Box with styling
- `Row` / `Column` - Horizontal/Vertical layout
- `ListView` - Scrollable list
- `Image` - Display images
- `TextField` - Text input
- `ElevatedButton` - Button
- `AppBar` - Top navigation bar
- `Scaffold` - Basic page structure

---

## 3. Project Structure & Architecture

### 3.1 Folder Structure

Our project follows this structure:

```
DriversandMinders/          # Driver & Bus Minder App
├── lib/
│   ├── main.dart           # App entry point
│   ├── core/
│   │   └── app_export.dart # Common imports
│   ├── presentation/       # UI Screens
│   │   ├── shared_login_screen/
│   │   ├── driver_start_shift_screen/
│   │   └── busminder_attendance_screen/
│   ├── services/           # API calls
│   │   └── api_service.dart
│   ├── widgets/            # Reusable UI components
│   ├── theme/              # App styling
│   ├── routes/             # Navigation
│   └── models/             # Data structures
├── assets/                 # Images, fonts, etc.
└── pubspec.yaml           # Dependencies

ParentsApp/                 # Parent App
└── (Similar structure)
```

### 3.2 Understanding Key Files

**main.dart** - Entry point:
```dart
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BusTracker Pro',
      home: SharedLoginScreen(),
    );
  }
}
```

**pubspec.yaml** - Dependencies:
```yaml
dependencies:
  flutter:
    sdk: flutter
  dio: ^5.4.0              # HTTP client for API calls
  shared_preferences: ^2.2.2  # Local storage
  geolocator: ^14.0.2      # GPS location
  sizer: ^3.1.3            # Responsive design
```

---

## 4. Working with REST APIs

### 4.1 What is a REST API?

A REST API is how your mobile app communicates with the backend server.

**Example:**
- Login: `POST /api/users/login/` with username & password
- Get children: `GET /api/parents/my-children/`
- Update profile: `PATCH /api/parents/1/`

### 4.2 HTTP Methods

- `GET` - Retrieve data (read)
- `POST` - Create new data
- `PUT` / `PATCH` - Update existing data
- `DELETE` - Remove data

### 4.3 API Service Implementation

**lib/services/api_service.dart:**

```dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Backend URL - CHANGE THIS to your server IP
  static const String baseUrl = 'http://192.168.100.43:8000';

  late Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add token to all requests
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
    ));
  }

  // Save token after login
  Future<void> _saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Load token on app start
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  // Example: Login
  Future<Map<String, dynamic>> login(String phone) async {
    try {
      final response = await _dio.post(
        '/api/parents/direct-phone-login/',
        data: {'phone_number': phone},
      );

      if (response.statusCode == 200) {
        await _saveToken(response.data['tokens']['access']);
        return response.data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Login failed');
      } else {
        throw Exception('Network error');
      }
    }
  }

  // Example: Get data
  Future<List<dynamic>> getChildren() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/parents/my-children/');

      if (response.statusCode == 200) {
        return response.data['children'];
      } else {
        throw Exception('Failed to load');
      }
    } on DioException catch (e) {
      throw Exception('Network error');
    }
  }
}
```

### 4.4 Using API Service in Screens

```dart
class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin(String phone) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.login(phone);

      // Success - navigate to home
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            onSubmitted: _handleLogin,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              errorText: _errorMessage,
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _handleLogin('1234567890'),
            child: _isLoading
              ? CircularProgressIndicator()
              : Text('Login'),
          ),
        ],
      ),
    );
  }
}
```

---

## 5. Building UI Components

### 5.1 Responsive Design with Sizer

Make your app look good on all screen sizes:

```dart
import 'package:sizer/sizer.dart';

// Wrap your app with Sizer
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) {
        return MaterialApp(
          home: HomeScreen(),
        );
      },
    );
  }
}

// Use responsive units
Container(
  width: 80.w,      // 80% of screen width
  height: 50.h,     // 50% of screen height
  padding: EdgeInsets.all(5.w),  // 5% padding
  child: Text(
    'Responsive Text',
    style: TextStyle(fontSize: 16.sp),  // Responsive font size
  ),
)
```

### 5.2 Common UI Patterns

**List of Items:**
```dart
ListView.builder(
  itemCount: children.length,
  itemBuilder: (context, index) {
    final child = children[index];
    return ListTile(
      leading: CircleAvatar(child: Text(child.name[0])),
      title: Text(child.name),
      subtitle: Text('Grade ${child.grade}'),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChildDetailScreen(child: child),
          ),
        );
      },
    );
  },
)
```

**Card Component:**
```dart
Card(
  elevation: 4,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(4.w),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bus Route A',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Icon(Icons.people, size: 20),
            SizedBox(width: 2.w),
            Text('28 students'),
          ],
        ),
      ],
    ),
  ),
)
```

**Form Input:**
```dart
class LoginForm extends StatefulWidget {
  final Function(String) onSubmit;

  const LoginForm({required this.onSubmit});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _controller = TextEditingController();
  bool _isValid = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_validate);
  }

  void _validate() {
    setState(() {
      _isValid = _controller.text.length >= 8;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        SizedBox(height: 2.h),
        ElevatedButton(
          onPressed: _isValid ? () => widget.onSubmit(_controller.text) : null,
          child: Text('Submit'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

---

## 6. State Management

### 6.1 What is State?

State is data that can change over time. Examples:
- User is logged in (true/false)
- List of children loaded from API
- Current GPS location

### 6.2 Local State (setState)

Use `setState` for simple, screen-specific state:

```dart
class CounterScreen extends StatefulWidget {
  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  int _count = 0;

  void _increment() {
    setState(() {
      _count++;  // Update state
    });  // Widget rebuilds with new count
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Count: $_count'),
            ElevatedButton(
              onPressed: _increment,
              child: Text('Increment'),
            ),
          ],
        ),
      ),
    );
  }
}
```

### 6.3 Loading States

Always show users what's happening:

```dart
class DataScreen extends StatefulWidget {
  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ApiService();
      final result = await apiService.getChildren();

      setState(() {
        _data = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red),
            SizedBox(height: 2.h),
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadData,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        return ListTile(title: Text(_data[index]['name']));
      },
    );
  }
}
```

---

## 7. Navigation & Routing

### 7.1 Basic Navigation

```dart
// Navigate to new screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => DetailScreen(),
  ),
);

// Go back
Navigator.pop(context);

// Replace current screen (login -> home)
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => HomeScreen(),
  ),
);
```

### 7.2 Named Routes

**lib/routes/app_routes.dart:**
```dart
import 'package:flutter/material.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String childDetail = '/child-detail';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => LoginScreen(),
    home: (context) => HomeScreen(),
    childDetail: (context) => ChildDetailScreen(),
  };
}
```

**main.dart:**
```dart
MaterialApp(
  initialRoute: AppRoutes.login,
  routes: AppRoutes.routes,
)

// Navigate using names
Navigator.pushNamed(context, AppRoutes.home);
Navigator.pushReplacementNamed(context, AppRoutes.login);
```

### 7.3 Passing Data Between Screens

```dart
// Navigate with arguments
Navigator.pushNamed(
  context,
  '/child-detail',
  arguments: {'childId': 123, 'name': 'John'},
);

// Receive arguments
class ChildDetailScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final childId = args['childId'];
    final name = args['name'];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Text('Child ID: $childId'),
    );
  }
}
```

---

## 8. Real-time Location Tracking

### 8.1 GPS Permissions

**android/app/src/main/AndroidManifest.xml:**
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

**ios/Runner/Info.plist:**
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to track the bus</string>
```

### 8.2 Getting Current Location

```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    // Request permission
    final permission = await Permission.location.request();
    if (!permission.isGranted) {
      return null;
    }

    // Check if location service is enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }
}

// Usage in screen
class LocationScreen extends StatefulWidget {
  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  Position? _currentPosition;

  Future<void> _getLocation() async {
    final locationService = LocationService();
    final position = await locationService.getCurrentLocation();

    setState(() {
      _currentPosition = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('Lat: ${_currentPosition?.latitude ?? "Unknown"}'),
          Text('Lng: ${_currentPosition?.longitude ?? "Unknown"}'),
          ElevatedButton(
            onPressed: _getLocation,
            child: Text('Get Location'),
          ),
        ],
      ),
    );
  }
}
```

### 8.3 Real-time Location Streaming

```dart
import 'dart:async';

class LiveLocationScreen extends StatefulWidget {
  @override
  State<LiveLocationScreen> createState() => _LiveLocationScreenState();
}

class _LiveLocationScreenState extends State<LiveLocationScreen> {
  StreamSubscription<Position>? _positionStream;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,  // Update every 10 meters
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });

      // Send to backend
      _sendLocationToServer(position);
    });
  }

  Future<void> _sendLocationToServer(Position position) async {
    final apiService = ApiService();
    await apiService.updateLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Tracking')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 64, color: Colors.blue),
            SizedBox(height: 2.h),
            Text('Latitude: ${_currentPosition?.latitude ?? "..."}'),
            Text('Longitude: ${_currentPosition?.longitude ?? "..."}'),
            Text('Speed: ${_currentPosition?.speed ?? 0} m/s'),
          ],
        ),
      ),
    );
  }
}
```

---

## 9. Local Data Storage

### 9.1 SharedPreferences (Simple Key-Value Storage)

```dart
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Save data
  Future<void> saveUserData({
    required String userId,
    required String userName,
    required bool isLoggedIn,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', userId);
    await prefs.setString('user_name', userName);
    await prefs.setBool('is_logged_in', isLoggedIn);
  }

  // Load data
  Future<Map<String, dynamic>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'user_id': prefs.getString('user_id'),
      'user_name': prefs.getString('user_name'),
      'is_logged_in': prefs.getBool('is_logged_in') ?? false,
    };
  }

  // Clear data (logout)
  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Check if logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }
}
```

### 9.2 Auto-Login on App Start

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(Duration(seconds: 2));  // Show splash for 2s

    final storageService = StorageService();
    final isLoggedIn = await storageService.isLoggedIn();

    if (isLoggedIn) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

## 10. Testing & Debugging

### 10.1 Debug Print Statements

```dart
void fetchData() async {
  print('🟢 Starting API call...');

  try {
    final response = await apiService.getData();
    print('🟢 API Response: $response');
  } catch (e) {
    print('🔴 Error: $e');
  }
}
```

### 10.2 Flutter DevTools

```bash
# Run your app
flutter run

# Access DevTools in browser
# Look for the link in terminal output
# http://127.0.0.1:9100/?uri=...
```

### 10.3 Common Issues & Solutions

**Issue: Hot reload not working**
```bash
# Full restart
r (in terminal)
# or
flutter run
```

**Issue: White screen / App crashes**
- Check terminal for error messages
- Look for `setState() called after dispose()`
- Ensure async operations check `if (mounted)` before `setState`

**Issue: API not connecting**
- Check backend is running
- Verify IP address in `ApiService.baseUrl`
- Test API in browser or Postman first
- Check phone and computer are on same network

**Issue: Location not working**
- Check permissions in AndroidManifest.xml / Info.plist
- Request runtime permissions
- Enable location on device
- Test on physical device, not emulator

---

## 11. Common Development Tasks

### 11.1 Adding a New Screen

**Step 1:** Create screen file
```dart
// lib/presentation/my_new_screen/my_new_screen.dart
import 'package:flutter/material.dart';

class MyNewScreen extends StatefulWidget {
  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My New Screen')),
      body: Center(child: Text('Hello World')),
    );
  }
}
```

**Step 2:** Add route
```dart
// lib/routes/app_routes.dart
static const String myNewScreen = '/my-new-screen';

static Map<String, WidgetBuilder> routes = {
  // ... existing routes
  myNewScreen: (context) => MyNewScreen(),
};
```

**Step 3:** Navigate to it
```dart
Navigator.pushNamed(context, AppRoutes.myNewScreen);
```

### 11.2 Adding a New API Endpoint

**Step 1:** Add method to ApiService
```dart
// lib/services/api_service.dart
Future<Map<String, dynamic>> getDriverProfile(int driverId) async {
  try {
    await loadToken();
    final response = await _dio.get('/api/drivers/$driverId/');

    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw Exception('Failed to load profile');
    }
  } on DioException catch (e) {
    throw Exception('Network error');
  }
}
```

**Step 2:** Use in screen
```dart
class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _apiService.getDriverProfile(1);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: Column(
        children: [
          Text('Name: ${_profile?['name']}'),
          Text('Email: ${_profile?['email']}'),
        ],
      ),
    );
  }
}
```

### 11.3 Adding a New Widget

**Step 1:** Create widget file
```dart
// lib/widgets/status_badge.dart
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({required this.status});

  Color get _color {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
```

**Step 2:** Use it
```dart
StatusBadge(status: 'active')
```

---

## 12. Best Practices

### 12.1 Code Organization

✅ **DO:**
- Keep screens in `presentation/` folder
- Keep reusable widgets in `widgets/` folder
- Keep API calls in `services/` folder
- Use meaningful file and variable names

❌ **DON'T:**
- Put everything in one file
- Use `var` for everything (be explicit with types)
- Hardcode values (use constants)

### 12.2 Error Handling

✅ **Always handle errors:**
```dart
try {
  final data = await apiService.getData();
  // Success
} catch (e) {
  // Show error to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

### 12.3 User Feedback

✅ **Always show loading states:**
```dart
if (_isLoading) {
  return CircularProgressIndicator();
}
```

✅ **Show success/error messages:**
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Profile updated successfully!'),
    backgroundColor: Colors.green,
  ),
);
```

### 12.4 Performance

✅ **Optimize lists:**
```dart
// Use ListView.builder instead of ListView
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ListTile(title: Text(items[index]));
  },
)
```

✅ **Dispose resources:**
```dart
@override
void dispose() {
  _controller.dispose();
  _stream.cancel();
  super.dispose();
}
```

### 12.5 Code Style

```dart
// ✅ Good: Descriptive names
final String userName = 'John';
Future<void> fetchUserProfile() async { }

// ❌ Bad: Unclear names
final String un = 'John';
Future<void> fup() async { }

// ✅ Good: Proper formatting
if (isLoggedIn) {
  navigateToHome();
} else {
  showLoginScreen();
}

// ❌ Bad: Hard to read
if(isLoggedIn){navigateToHome();}else{showLoginScreen();}

// ✅ Good: Constants
static const String apiUrl = 'http://192.168.1.1:8000';

// ❌ Bad: Hardcoded everywhere
final response = await dio.get('http://192.168.1.1:8000/api/...');
```

---

## Quick Reference Cheat Sheet

### Flutter Commands
```bash
flutter create my_app        # Create new project
flutter run                  # Run app
flutter pub get              # Install dependencies
flutter clean                # Clean build files
flutter doctor               # Check setup
```

### Common Widgets
```dart
Text('Hello')
Container(width: 100, height: 100, color: Colors.blue)
Row(children: [...])
Column(children: [...])
ListView.builder(...)
TextField(controller: _controller)
ElevatedButton(onPressed: () {}, child: Text('Click'))
```

### API Calls
```dart
// GET
final response = await _dio.get('/api/endpoint/');

// POST
final response = await _dio.post('/api/endpoint/', data: {...});

// PATCH
final response = await _dio.patch('/api/endpoint/', data: {...});
```

### Navigation
```dart
Navigator.pushNamed(context, '/screen');
Navigator.pop(context);
Navigator.pushReplacementNamed(context, '/screen');
```

---

## Next Steps

1. **Complete Flutter Basics Tutorial:** https://docs.flutter.dev/get-started/codelab
2. **Build a Simple Todo App:** Practice CRUD operations
3. **Read our codebase:** Start with `ParentsApp/lib/presentation/parent_login_screen/`
4. **Make your first change:** Add a simple feature like "Last Login Time"
5. **Ask questions:** Don't hesitate to ask senior developers

**Remember:** Everyone starts as a beginner. The key is consistent practice and asking questions when stuck!

---

## Useful Resources

- **Flutter Docs:** https://docs.flutter.dev/
- **Dart Language Tour:** https://dart.dev/guides/language/language-tour
- **Pub.dev (Packages):** https://pub.dev/
- **Flutter YouTube Channel:** https://www.youtube.com/@flutterdev
- **Stack Overflow:** https://stackoverflow.com/questions/tagged/flutter

---

**Document Version:** 1.0
**Last Updated:** October 2024
**Maintainer:** Development Team
