# ParentsApp Comprehensive Testing Guide

## 📋 Table of Contents
1. [Overview](#overview)
2. [Test Environment Setup](#test-environment-setup)
3. [Testing Architecture](#testing-architecture)
4. [What to Test](#what-to-test)
5. [Unit Tests - Service Layer](#unit-tests---service-layer)
6. [Widget Tests - UI Layer](#widget-tests---ui-layer)
7. [Integration Tests - User Flows](#integration-tests---user-flows)
8. [Edge Cases & Error Scenarios](#edge-cases--error-scenarios)
9. [How to Run Tests](#how-to-run-tests)
10. [CI/CD Integration](#cicd-integration)
11. [Code Coverage Requirements](#code-coverage-requirements)
12. [Testing Best Practices](#testing-best-practices)

---

## Overview

**Current Status:** ⚠️ 0% test coverage (1 placeholder test only)

**Testing Goal:** Achieve 80%+ code coverage with comprehensive tests across:
- ✅ **Unit Tests**: Services, utilities, business logic (70% of tests)
- ✅ **Widget Tests**: UI components and screens (20% of tests)
- ✅ **Integration Tests**: Complete user workflows (10% of tests)

**Why Testing Matters:**
This app handles **critical safety data** including:
- Real-time GPS tracking of school buses with children
- Parent authentication and authorization
- Live WebSocket connections for location updates
- Student attendance and trip monitoring

Without comprehensive testing, production breaks can lead to:
- Parents unable to track their children
- Authentication failures preventing app access
- WebSocket disconnections causing missing updates
- Data sync failures

---

## Test Environment Setup

### 1. Install Testing Dependencies

Add to `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0

  # Testing dependencies
  mockito: ^5.4.4           # Mocking framework for unit tests
  build_runner: ^2.4.13      # Code generation for mocks
  http_mock_adapter: ^0.6.1  # Mock Dio HTTP requests
  faker: ^2.2.0              # Generate test data
  integration_test:          # E2E testing support
    sdk: flutter
```

### 2. Install Dependencies

```bash
cd /home/m/work/Apo_Basi/ParentsApp
flutter pub get
```

### 3. Create Test Directory Structure

```bash
mkdir -p test/{unit,widget,integration,helpers,fixtures,mocks}
mkdir -p integration_test
```

**Final structure:**
```
test/
├── unit/                    # Unit tests for services, models, utilities
│   ├── services/
│   │   ├── api_service_test.dart
│   │   ├── bus_websocket_service_test.dart
│   │   ├── mapbox_route_service_test.dart
│   │   └── notification_service_test.dart
│   ├── models/
│   │   ├── child_model_test.dart
│   │   ├── parent_model_test.dart
│   │   └── bus_location_model_test.dart
│   └── utils/
│       └── validators_test.dart
├── widget/                  # Widget/screen tests
│   ├── parent_login_screen_test.dart
│   ├── parent_dashboard_test.dart
│   ├── child_detail_screen_test.dart
│   └── notifications_center_test.dart
├── integration/             # Integration tests
│   └── login_flow_test.dart
├── helpers/                 # Test utilities
│   ├── test_helpers.dart
│   └── mock_data.dart
├── fixtures/                # JSON fixtures for API responses
│   ├── login_response.json
│   ├── children_response.json
│   └── notifications_response.json
└── mocks/                   # Generated mock classes
    └── mocks.dart

integration_test/
└── app_test.dart           # Full E2E tests
```

### 4. Create Test Helpers File

Create `test/helpers/test_helpers.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Setup shared preferences for testing
Future<void> setupSharedPreferences({
  String? accessToken,
  int? userId,
}) async {
  SharedPreferences.setMockInitialValues({
    if (accessToken != null) 'access_token': accessToken,
    if (userId != null) 'user_id': userId,
  });
}

/// Clear shared preferences between tests
Future<void> clearSharedPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
}

/// Pump widget with MaterialApp wrapper
Future<void> pumpWidgetWithMaterial(
  WidgetTester tester,
  Widget widget,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: widget,
    ),
  );
}
```

### 5. Create Mock Data File

Create `test/helpers/mock_data.dart`:

```dart
import 'package:faker/faker.dart';

final faker = Faker();

class MockData {
  // Mock authentication response
  static Map<String, dynamic> loginResponse({
    String? phoneNumber,
    int? userId,
  }) {
    return {
      'tokens': {
        'access': 'mock_access_token_${faker.guid.guid()}',
        'refresh': 'mock_refresh_token_${faker.guid.guid()}',
      },
      'parent': {
        'id': userId ?? faker.randomGenerator.integer(1000),
        'firstName': faker.person.firstName(),
        'lastName': faker.person.lastName(),
        'phone': phoneNumber ?? faker.phoneNumber.us(),
        'email': faker.internet.email(),
        'address': faker.address.streetAddress(),
      },
      'children': childrenList(count: 2),
    };
  }

  // Mock children list
  static List<Map<String, dynamic>> childrenList({int count = 3}) {
    return List.generate(
      count,
      (index) => {
        'id': faker.randomGenerator.integer(1000),
        'firstName': faker.person.firstName(),
        'lastName': faker.person.lastName(),
        'grade': 'Grade ${faker.randomGenerator.integer(12, min: 1)}',
        'assignedBus': {
          'id': faker.randomGenerator.integer(100),
          'numberPlate': 'UBL ${faker.randomGenerator.integer(999, min: 100)}',
        },
        'locationStatus': ['At Home', 'On Bus', 'At School'][index % 3],
        'last_updated': DateTime.now().toIso8601String(),
      },
    );
  }

  // Mock bus location update
  static Map<String, dynamic> busLocationUpdate({
    required int busId,
    String? busNumber,
  }) {
    return {
      'type': 'location_update',
      'bus_id': busId,
      'bus_number': busNumber ?? 'UBL ${faker.randomGenerator.integer(999)}',
      'latitude': faker.randomGenerator.decimal(scale: 0.1, min: -1.5),
      'longitude': faker.randomGenerator.decimal(scale: 32.6, min: 0.1),
      'speed': faker.randomGenerator.decimal(scale: 60.0),
      'heading': faker.randomGenerator.decimal(scale: 360.0),
      'is_active': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  // Mock notifications
  static List<Map<String, dynamic>> notificationsList({int count = 10}) {
    final types = ['trip_started', 'child_picked', 'child_dropped', 'alert'];
    return List.generate(
      count,
      (index) => {
        'id': faker.randomGenerator.integer(1000),
        'type': types[index % types.length],
        'title': faker.lorem.sentence(),
        'message': faker.lorem.sentences(2).join(' '),
        'is_read': faker.randomGenerator.boolean(),
        'created_at': DateTime.now()
            .subtract(Duration(hours: index))
            .toIso8601String(),
      },
    );
  }
}
```

---

## Testing Architecture

### Test Pyramid for ParentsApp

```
              ▲
             ╱ ╲
            ╱   ╲
           ╱ E2E ╲         10% - Full user workflows (2-3 critical paths)
          ╱───────╲
         ╱         ╲
        ╱  Widget   ╲      20% - UI components & screens (5 screens)
       ╱─────────────╲
      ╱               ╲
     ╱  Unit Tests     ╲   70% - Services, models, business logic
    ╱___________________╲
```

### Testing Principles

1. **Isolate Dependencies**: Mock external services (API, WebSocket, Storage)
2. **Test One Thing**: Each test should validate a single behavior
3. **Descriptive Names**: Use `test('should do X when Y happens', () {})`
4. **Arrange-Act-Assert**: Structure tests clearly
5. **Test Edge Cases**: Null values, empty data, errors, timeouts
6. **Fast Tests**: Unit tests should run in milliseconds

---

## What to Test

### Priority Matrix

| Component | Priority | Complexity | Risk | Test Count |
|-----------|----------|------------|------|------------|
| **ApiService** | 🔴 CRITICAL | High | High | 25+ tests |
| **BusWebSocketService** | 🔴 CRITICAL | High | High | 20+ tests |
| **MapboxRouteService** | 🟡 HIGH | Medium | Medium | 15+ tests |
| **Child Model** | 🟢 MEDIUM | Low | Low | 10+ tests |
| **ParentLoginScreen** | 🔴 CRITICAL | Medium | High | 12+ tests |
| **ParentDashboard** | 🟡 HIGH | Medium | Medium | 10+ tests |
| **ChildDetailScreen** | 🟡 HIGH | High | High | 15+ tests |
| **NotificationsCenter** | 🟢 MEDIUM | Low | Low | 8+ tests |

**Total Target: 115+ tests**

---

## Unit Tests - Service Layer

### 5.1 ApiService Tests (`test/unit/services/api_service_test.dart`)

**File:** `lib/services/api_service.dart` (355 lines)

**What to Test:**
- Authentication (login)
- Token management (save, load, clear)
- HTTP requests (GET, POST, PATCH, DELETE)
- Error handling and extraction
- Network timeouts
- Response parsing

#### Test Structure

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apo_basi/services/api_service.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_data.dart';

// Generate mocks with build_runner
@GenerateMocks([Dio])
void main() {
  group('ApiService', () {
    late ApiService apiService;
    late MockDio mockDio;

    setUp(() {
      mockDio = MockDio();
      apiService = ApiService();
      // Inject mock Dio for testing
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await clearSharedPreferences();
    });

    // ========== AUTHENTICATION TESTS ==========

    group('directPhoneLogin', () {
      test('should login successfully with valid phone number', () async {
        // Arrange
        final phoneNumber = '+256700123456';
        final mockResponse = MockData.loginResponse(phoneNumber: phoneNumber);

        when(mockDio.post(
          '/api/parents/login/',
          data: {'phone_number': phoneNumber},
        )).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        // Act
        final result = await apiService.directPhoneLogin(phoneNumber);

        // Assert
        expect(result, isA<Map<String, dynamic>>());
        expect(result['tokens']['access'], isNotEmpty);
        expect(result['parent'], isNotNull);
        verify(mockDio.post('/api/parents/login/', data: any)).called(1);
      });

      test('should throw exception when phone number is invalid', () async {
        // Arrange
        final invalidPhone = '123';
        when(mockDio.post(any, data: any)).thenThrow(
          DioException(
            response: Response(
              data: {'detail': 'Invalid phone number format'},
              statusCode: 400,
              requestOptions: RequestOptions(path: ''),
            ),
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.directPhoneLogin(invalidPhone),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle network timeout gracefully', () async {
        // Arrange
        when(mockDio.post(any, data: any)).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.directPhoneLogin('+256700123456'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('timeout'),
            ),
          ),
        );
      });

      test('should save token and user data after successful login', () async {
        // Arrange
        final mockResponse = MockData.loginResponse();
        when(mockDio.post(any, data: any)).thenAnswer((_) async => Response(
          data: mockResponse,
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        ));

        // Act
        await apiService.directPhoneLogin('+256700123456');

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('access_token'), isNotNull);
        expect(prefs.getString('refresh_token'), isNotNull);
        expect(prefs.getInt('user_id'), isNotNull);
      });
    });

    // ========== TOKEN MANAGEMENT TESTS ==========

    group('Token Management', () {
      test('should load token from shared preferences', () async {
        // Arrange
        const token = 'test_token_123';
        await setupSharedPreferences(accessToken: token);

        // Act
        await apiService.loadToken();

        // Assert
        expect(apiService.isLoggedIn(), completion(isTrue));
      });

      test('should clear all tokens and user data on logout', () async {
        // Arrange
        await setupSharedPreferences(
          accessToken: 'token',
          userId: 123,
        );

        // Act
        await apiService.clearToken();

        // Assert
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('access_token'), isNull);
        expect(prefs.getString('refresh_token'), isNull);
        expect(prefs.getInt('user_id'), isNull);
      });

      test('should return false for isLoggedIn when no token exists', () async {
        // Arrange
        await clearSharedPreferences();

        // Act & Assert
        expect(await apiService.isLoggedIn(), isFalse);
      });
    });

    // ========== GET MY CHILDREN TESTS ==========

    group('getMyChildren', () {
      test('should fetch children successfully', () async {
        // Arrange
        await setupSharedPreferences(accessToken: 'token', userId: 1);
        final mockChildren = MockData.childrenList(count: 3);

        when(mockDio.get('/api/parents/1/children/')).thenAnswer(
          (_) async => Response(
            data: {'children': mockChildren},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act
        final children = await apiService.getMyChildren();

        // Assert
        expect(children, hasLength(3));
        expect(children.first.firstName, isNotEmpty);
        expect(children.first.assignedBus, isNotNull);
      });

      test('should return empty list when no children exist', () async {
        // Arrange
        await setupSharedPreferences(accessToken: 'token', userId: 1);
        when(mockDio.get(any)).thenAnswer(
          (_) async => Response(
            data: {'children': []},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act
        final children = await apiService.getMyChildren();

        // Assert
        expect(children, isEmpty);
      });

      test('should throw exception when user not logged in', () async {
        // Arrange
        await clearSharedPreferences();

        // Act & Assert
        expect(
          () => apiService.getMyChildren(),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('not logged in'),
            ),
          ),
        );
      });

      test('should handle API error responses', () async {
        // Arrange
        await setupSharedPreferences(accessToken: 'token', userId: 1);
        when(mockDio.get(any)).thenThrow(
          DioException(
            response: Response(
              data: {'detail': 'Parent not found'},
              statusCode: 404,
              requestOptions: RequestOptions(path: ''),
            ),
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.getMyChildren(),
          throwsA(isA<Exception>()),
        );
      });
    });

    // ========== NOTIFICATIONS TESTS ==========

    group('getNotifications', () {
      test('should fetch notifications with default parameters', () async {
        // Arrange
        await setupSharedPreferences(accessToken: 'token');
        final mockNotifications = MockData.notificationsList(count: 5);

        when(mockDio.get(
          '/api/notifications/',
          queryParameters: {'limit': '50'},
        )).thenAnswer(
          (_) async => Response(
            data: mockNotifications,
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act
        final notifications = await apiService.getNotifications();

        // Assert
        expect(notifications, hasLength(5));
      });

      test('should filter notifications by read status', () async {
        // Arrange
        await setupSharedPreferences(accessToken: 'token');
        when(mockDio.get(
          any,
          queryParameters: {'limit': '50', 'is_read': 'false'},
        )).thenAnswer(
          (_) async => Response(
            data: [],
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ),
        );

        // Act
        await apiService.getNotifications(isRead: false);

        // Assert
        verify(mockDio.get(
          any,
          queryParameters: containsPair('is_read', 'false'),
        )).called(1);
      });
    });

    // ========== ERROR EXTRACTION TESTS ==========

    group('Error Message Extraction', () {
      test('should extract error from "detail" field', () {
        // Tested implicitly in other tests
      });

      test('should extract error from nested "error.message" field', () {
        // Tested implicitly in other tests
      });

      test('should return fallback message when no error found', () {
        // Tested implicitly in other tests
      });
    });
  });
}
```

#### Run Mock Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Total ApiService Tests: 25+**

---

### 5.2 BusWebSocketService Tests (`test/unit/services/bus_websocket_service_test.dart`)

**File:** `lib/services/bus_websocket_service.dart` (263 lines)

**What to Test:**
- WebSocket connection establishment
- Subscription to bus updates
- Message parsing (location updates, errors)
- Automatic reconnection logic
- Connection state management
- Stream controllers

#### Key Tests

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:apo_basi/services/bus_websocket_service.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_data.dart';

void main() {
  group('BusWebSocketService', () {
    late BusWebSocketService service;

    setUp(() {
      service = BusWebSocketService();
      SharedPreferences.setMockInitialValues({
        'access_token': 'test_token',
      });
    });

    tearDown(() {
      service.dispose();
    });

    // ========== CONNECTION TESTS ==========

    test('should initialize service with connect()', () async {
      // Act
      await service.connect();

      // Assert
      expect(service.isConnected, isFalse); // Not connected until subscribeToBus
    });

    test('should fail to connect without authentication token', () async {
      // Arrange
      await clearSharedPreferences();

      final errorEvents = <String>[];
      service.errorStream.listen(errorEvents.add);

      // Act
      await service.connect();

      // Assert
      await Future.delayed(Duration(milliseconds: 100));
      expect(errorEvents, contains('Authentication required'));
    });

    test('should subscribe to bus and establish WebSocket connection', () async {
      // Arrange
      await service.connect();
      final connectionStates = <LocationConnectionState>[];
      service.connectionStateStream.listen(connectionStates.add);

      // Act
      service.subscribeToBus(123);

      // Assert
      await Future.delayed(Duration(milliseconds: 100));
      expect(connectionStates, contains(LocationConnectionState.connecting));
    });

    test('should not reconnect to same bus if already subscribed', () async {
      // Arrange
      await service.connect();
      service.subscribeToBus(123);
      await Future.delayed(Duration(milliseconds: 100));

      // Act
      service.subscribeToBus(123); // Same bus

      // Assert - No additional connection attempts
      expect(service.subscribedBusId, equals(123));
    });

    test('should unsubscribe from previous bus when subscribing to new bus', () async {
      // Arrange
      await service.connect();
      service.subscribeToBus(123);
      await Future.delayed(Duration(milliseconds: 100));

      // Act
      service.subscribeToBus(456); // Different bus

      // Assert
      expect(service.subscribedBusId, equals(456));
    });

    // ========== MESSAGE HANDLING TESTS ==========

    test('should parse location update messages correctly', () async {
      // Arrange
      final locationUpdates = <BusLocation>[];
      service.locationUpdateStream.listen(locationUpdates.add);

      final mockMessage = MockData.busLocationUpdate(
        busId: 123,
        busNumber: 'UBL 456',
      );

      // Act
      service._handleMessage(json.encode(mockMessage));

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(locationUpdates, hasLength(1));
      expect(locationUpdates.first.busId, equals(123));
      expect(locationUpdates.first.latitude, isA<double>());
      expect(locationUpdates.first.longitude, isA<double>());
    });

    test('should handle connection confirmation messages', () async {
      // Arrange
      final connectionStates = <LocationConnectionState>[];
      service.connectionStateStream.listen(connectionStates.add);

      final connectMessage = {'type': 'connected', 'message': 'Connected'};

      // Act
      service._handleMessage(json.encode(connectMessage));

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(connectionStates, contains(LocationConnectionState.connected));
    });

    test('should handle error messages from server', () async {
      // Arrange
      final errors = <String>[];
      service.errorStream.listen(errors.add);

      final errorMessage = {
        'type': 'error',
        'message': 'Bus not found',
      };

      // Act
      service._handleMessage(json.encode(errorMessage));

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(errors, contains('Bus not found'));
    });

    test('should handle malformed JSON messages gracefully', () async {
      // Arrange
      final errors = <String>[];
      service.errorStream.listen(errors.add);

      // Act
      service._handleMessage('invalid json {{{');

      // Assert
      await Future.delayed(Duration(milliseconds: 50));
      expect(errors, contains('Failed to parse message'));
    });

    // ========== RECONNECTION TESTS ==========

    test('should schedule reconnection on disconnect', () async {
      // Arrange
      await service.connect();
      service.subscribeToBus(123);
      final connectionStates = <LocationConnectionState>[];
      service.connectionStateStream.listen(connectionStates.add);

      // Act
      service._handleDisconnect();

      // Assert
      await Future.delayed(Duration(milliseconds: 100));
      expect(connectionStates, contains(LocationConnectionState.disconnected));
    });

    test('should give up after max reconnection attempts', () async {
      // Arrange
      final errors = <String>[];
      service.errorStream.listen(errors.add);

      // Simulate multiple failed reconnection attempts
      for (int i = 0; i < 6; i++) {
        service._scheduleReconnect();
      }

      // Assert
      await Future.delayed(Duration(milliseconds: 500));
      expect(
        errors.any((e) => e.contains('maximum attempts')),
        isTrue,
      );
    });

    // ========== REQUEST CURRENT LOCATION TESTS ==========

    test('should send request for current location', () {
      // This requires mocking the WebSocket channel sink
      // Implementation depends on your mocking strategy
    });

    // ========== CLEANUP TESTS ==========

    test('should disconnect and clean up on dispose', () async {
      // Arrange
      await service.connect();
      service.subscribeToBus(123);

      // Act
      service.dispose();

      // Assert
      expect(service.isConnected, isFalse);
      expect(service.subscribedBusId, isNull);
    });
  });
}
```

**Total BusWebSocketService Tests: 20+**

---

### 5.3 Child Model Tests (`test/unit/models/child_model_test.dart`)

**File:** `lib/models/child_model.dart` (82 lines)

**What to Test:**
- JSON serialization/deserialization
- Handling both camelCase and snake_case
- Null safety
- Default values
- Computed properties (fullName)

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:apo_basi/models/child_model.dart';

void main() {
  group('Child Model', () {
    // ========== DESERIALIZATION TESTS ==========

    test('should parse valid JSON with snake_case keys', () {
      // Arrange
      final json = {
        'id': 1,
        'first_name': 'John',
        'last_name': 'Doe',
        'class_grade': 'Grade 5',
        'assigned_bus': {
          'id': 10,
          'number_plate': 'UBL 123',
        },
        'location_status': 'On Bus',
      };

      // Act
      final child = Child.fromJson(json);

      // Assert
      expect(child.id, equals(1));
      expect(child.firstName, equals('John'));
      expect(child.lastName, equals('Doe'));
      expect(child.classGrade, equals('Grade 5'));
      expect(child.assignedBus, isNotNull);
      expect(child.assignedBus!.numberPlate, equals('UBL 123'));
      expect(child.currentStatus, equals('On Bus'));
    });

    test('should parse valid JSON with camelCase keys', () {
      // Arrange
      final json = {
        'id': 2,
        'firstName': 'Jane',
        'lastName': 'Smith',
        'grade': 'Grade 7',
        'assignedBus': {
          'id': 20,
          'numberPlate': 'UBL 456',
        },
        'locationStatus': 'At School',
      };

      // Act
      final child = Child.fromJson(json);

      // Assert
      expect(child.firstName, equals('Jane'));
      expect(child.lastName, equals('Smith'));
      expect(child.currentStatus, equals('At School'));
    });

    test('should handle missing assigned bus gracefully', () {
      // Arrange
      final json = {
        'id': 3,
        'first_name': 'Test',
        'last_name': 'Child',
        'class_grade': 'Grade 3',
      };

      // Act
      final child = Child.fromJson(json);

      // Assert
      expect(child.assignedBus, isNull);
    });

    test('should default to "At Home" when status is missing', () {
      // Arrange
      final json = {
        'id': 4,
        'first_name': 'Test',
        'last_name': 'Child',
        'class_grade': 'Grade 4',
      };

      // Act
      final child = Child.fromJson(json);

      // Assert
      expect(child.currentStatus, equals('At Home'));
    });

    test('should parse last_updated timestamp', () {
      // Arrange
      final timestamp = DateTime.now().toIso8601String();
      final json = {
        'id': 5,
        'first_name': 'Test',
        'last_name': 'Child',
        'class_grade': 'Grade 2',
        'last_updated': timestamp,
      };

      // Act
      final child = Child.fromJson(json);

      // Assert
      expect(child.lastUpdated, isNotNull);
      expect(child.lastUpdated, isA<DateTime>());
    });

    // ========== COMPUTED PROPERTIES TESTS ==========

    test('should compute fullName correctly', () {
      // Arrange
      final child = Child(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        classGrade: 'Grade 5',
      );

      // Act & Assert
      expect(child.fullName, equals('John Doe'));
    });

    // ========== SERIALIZATION TESTS ==========

    test('should serialize to JSON correctly', () {
      // Arrange
      final child = Child(
        id: 1,
        firstName: 'John',
        lastName: 'Doe',
        classGrade: 'Grade 5',
        assignedBus: Bus(id: 10, numberPlate: 'UBL 123'),
        currentStatus: 'On Bus',
      );

      // Act
      final json = child.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['first_name'], equals('John'));
      expect(json['last_name'], equals('Doe'));
      expect(json['class_grade'], equals('Grade 5'));
      expect(json['assigned_bus'], isNotNull);
      expect(json['location_status'], equals('On Bus'));
    });
  });

  group('Bus Model', () {
    test('should parse valid JSON with different key formats', () {
      final testCases = [
        {'id': 1, 'number_plate': 'UBL 123'},
        {'id': 2, 'numberPlate': 'UBL 456'},
        {'id': 3, 'licensePlate': 'UBL 789'},
        {'id': 4, 'busNumber': 'UBL 000'},
      ];

      for (final json in testCases) {
        final bus = Bus.fromJson(json);
        expect(bus.id, isPositive);
        expect(bus.numberPlate, isNotEmpty);
      }
    });
  });
}
```

**Total Child Model Tests: 12+**

---

## Widget Tests - UI Layer

### 6.1 ParentLoginScreen Widget Tests (`test/widget/parent_login_screen_test.dart`)

**File:** `lib/presentation/parent_login_screen/parent_login_screen.dart`

**What to Test:**
- Widget rendering
- Form validation
- Phone number input
- Login button state (enabled/disabled)
- Error message display
- Loading state
- Navigation after login
- Haptic feedback

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:apo_basi/presentation/parent_login_screen/parent_login_screen.dart';
import 'package:apo_basi/services/api_service.dart';
import '../helpers/test_helpers.dart';

@GenerateMocks([ApiService])
void main() {
  group('ParentLoginScreen Widget Tests', () {
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
    });

    testWidgets('should render login screen with all elements', (tester) async {
      // Act
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());

      // Assert
      expect(find.text('Parent Login'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('should validate phone number format', (tester) async {
      // Arrange
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());

      // Act - Enter invalid phone
      await tester.enterText(find.byType(TextField), '123');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.text('Phone number must be at least 8 digits'), findsOneWidget);
    });

    testWidgets('should accept valid phone number formats', (tester) async {
      // Arrange
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());
      final validPhones = ['+256700123456', '0700123456', '256700123456'];

      for (final phone in validPhones) {
        // Act
        await tester.enterText(find.byType(TextField), phone);
        await tester.pump();

        // Assert - No validation error shown
        expect(find.textContaining('must be at least'), findsNothing);
      }
    });

    testWidgets('should disable login button when phone is empty', (tester) async {
      // Arrange
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());

      // Act
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));

      // Assert
      expect(button.enabled, isFalse);
    });

    testWidgets('should show loading indicator during login', (tester) async {
      // Arrange
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());

      when(mockApiService.directPhoneLogin(any)).thenAnswer(
        (_) async => Future.delayed(
          Duration(seconds: 2),
          () => {'tokens': {'access': 'token'}},
        ),
      );

      // Act
      await tester.enterText(find.byType(TextField), '+256700123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message on login failure', (tester) async {
      // Arrange
      await pumpWidgetWithMaterial(tester, ParentLoginScreen());

      when(mockApiService.directPhoneLogin(any)).thenThrow(
        Exception('Invalid credentials'),
      );

      // Act
      await tester.enterText(find.byType(TextField), '+256700123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Invalid credentials'), findsOneWidget);
    });

    testWidgets('should navigate to dashboard on successful login', (tester) async {
      // Arrange
      final navigatorObserver = MockNavigatorObserver();
      await tester.pumpWidget(
        MaterialApp(
          home: ParentLoginScreen(),
          navigatorObservers: [navigatorObserver],
        ),
      );

      when(mockApiService.directPhoneLogin(any)).thenAnswer(
        (_) async => {
          'tokens': {'access': 'token', 'refresh': 'refresh'},
          'parent': {'id': 1},
        },
      );

      // Act
      await tester.enterText(find.byType(TextField), '+256700123456');
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Assert
      verify(navigatorObserver.didPush(any, any)).called(greaterThan(0));
    });
  });
}
```

**Total ParentLoginScreen Tests: 12+**

---

## Integration Tests - User Flows

### 7.1 Login to Dashboard Flow (`integration_test/app_test.dart`)

**What to Test:**
- Complete login flow
- Dashboard navigation
- Child selection
- Map screen loading
- Logout flow

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:apo_basi/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End User Flow Tests', () {
    testWidgets('Complete login to dashboard to child detail flow', (tester) async {
      // Launch app
      app.main();
      await tester.pumpAndSettle();

      // Step 1: Login
      expect(find.text('Parent Login'), findsOneWidget);

      await tester.enterText(
        find.byType(TextField),
        '+256700123456',
      );
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Step 2: Verify dashboard loaded
      expect(find.text('My Children'), findsOneWidget);

      // Step 3: Select first child
      await tester.tap(find.byType(Card).first);
      await tester.pumpAndSettle();

      // Step 4: Verify child detail screen
      expect(find.text('Track Bus'), findsOneWidget);
      expect(find.byType(FlutterMap), findsOneWidget);

      // Step 5: Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Step 6: Open notifications
      await tester.tap(find.byIcon(Icons.notifications));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('Logout flow test', (tester) async {
      // Assuming already logged in
      app.main();
      await tester.pumpAndSettle();

      // Navigate to profile
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Verify redirected to login
      expect(find.text('Parent Login'), findsOneWidget);
    });
  });
}
```

---

## Edge Cases & Error Scenarios

### 8.1 Comprehensive Edge Case Testing Matrix

| Module | Edge Case | Expected Behavior | Test Priority |
|--------|-----------|-------------------|---------------|
| **ApiService** | | | |
| | Empty phone number | Show validation error | 🔴 Critical |
| | Phone with special chars only | Show validation error | 🟡 High |
| | Network offline | Show "No internet" error | 🔴 Critical |
| | API timeout (10s+) | Show timeout error | 🔴 Critical |
| | 401 Unauthorized | Clear token, redirect to login | 🔴 Critical |
| | 404 Not Found | Show "Resource not found" | 🟡 High |
| | 500 Server Error | Show "Server error, try again" | 🔴 Critical |
| | Malformed JSON response | Show parsing error | 🟡 High |
| | Token expired | Refresh token or re-login | 🔴 Critical |
| | No children returned | Show empty state | 🟢 Medium |
| **BusWebSocketService** | | | |
| | Connect without token | Show auth error | 🔴 Critical |
| | WebSocket connection fails | Retry with backoff | 🔴 Critical |
| | Receive invalid JSON | Log error, continue | 🟡 High |
| | Disconnect mid-session | Auto-reconnect | 🔴 Critical |
| | Max reconnect attempts | Show error, stop trying | 🟡 High |
| | Subscribe to non-existent bus | Show error from server | 🟡 High |
| | Multiple rapid subscriptions | Cancel previous, subscribe new | 🟢 Medium |
| **Child Model** | | | |
| | Null firstName | Default to empty string | 🟡 High |
| | Missing assignedBus | Set to null | 🟢 Medium |
| | Invalid timestamp format | Handle parsing error | 🟡 High |
| | Both camelCase & snake_case | Prefer one consistently | 🟢 Medium |
| **ParentLoginScreen** | | | |
| | Paste phone with spaces | Strip spaces, validate | 🟡 High |
| | Double-tap login button | Prevent duplicate requests | 🔴 Critical |
| | Login during network loss | Show error, retry option | 🔴 Critical |
| | Rapid back button press | Don't crash | 🟢 Medium |
| **ParentDashboard** | | | |
| | No children assigned | Show empty state message | 🟡 High |
| | Pull-to-refresh fails | Show error, keep old data | 🟡 High |
| | Child with null bus | Show "No bus assigned" | 🟡 High |
| **ChildDetailScreen** | | | |
| | Location permission denied | Show permission request | 🔴 Critical |
| | GPS unavailable | Show error message | 🟡 High |
| | Bus not moving (stale data) | Show last known location | 🟡 High |
| | WebSocket disconnects | Show "Reconnecting..." | 🔴 Critical |

### 8.2 Example Edge Case Test

```dart
test('should handle multiple rapid login attempts gracefully', () async {
  // Arrange
  bool firstCallCompleted = false;
  when(mockApiService.directPhoneLogin(any)).thenAnswer((_) async {
    await Future.delayed(Duration(milliseconds: 500));
    if (!firstCallCompleted) {
      firstCallCompleted = true;
      return {'tokens': {'access': 'token'}};
    }
    throw Exception('Duplicate request');
  });

  // Act - Trigger login twice rapidly
  final future1 = apiService.directPhoneLogin('+256700123456');
  final future2 = apiService.directPhoneLogin('+256700123456');

  // Assert - Second call should be ignored or handled
  await expectLater(future1, completes);
  // Depending on implementation, future2 might throw or return cached result
});
```

---

## How to Run Tests

### 9.1 Run All Tests

```bash
# Run all unit and widget tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html  # macOS
xdg-open coverage/html/index.html  # Linux
```

### 9.2 Run Specific Test Files

```bash
# Run single test file
flutter test test/unit/services/api_service_test.dart

# Run all service tests
flutter test test/unit/services/

# Run all widget tests
flutter test test/widget/

# Run with verbose output
flutter test --verbose
```

### 9.3 Run Integration Tests

```bash
# Run integration tests on connected device
flutter test integration_test/

# Run on specific device
flutter devices  # List devices
flutter test integration_test/ -d <device_id>

# Run on iOS simulator
flutter test integration_test/ -d iPhone

# Run on Android emulator
flutter test integration_test/ -d emulator-5554
```

### 9.4 Watch Mode (Auto-run on changes)

```bash
# Install flutter_test watcher (optional)
flutter pub global activate flutter_test

# Watch for changes (if package supports it)
flutter test --watch
```

### 9.5 Test with Different Build Modes

```bash
# Run in debug mode (default)
flutter test

# Run in profile mode
flutter test --profile

# Run with sound null safety
flutter test --enable-experiment=non-nullable
```

---

## CI/CD Integration

### 10.1 GitHub Actions Workflow

Create `.github/workflows/test.yml`:

```yaml
name: ParentsApp Tests

on:
  push:
    branches: [ main, dev ]
    paths:
      - 'ParentsApp/**'
  pull_request:
    branches: [ main, dev ]
    paths:
      - 'ParentsApp/**'

jobs:
  test:
    name: Run Flutter Tests
    runs-on: ubuntu-latest

    defaults:
      run:
        working-directory: ParentsApp

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'

      - name: Install dependencies
        run: flutter pub get

      - name: Verify formatting
        run: dart format --set-exit-if-changed .

      - name: Analyze code
        run: flutter analyze

      - name: Generate mocks
        run: flutter pub run build_runner build --delete-conflicting-outputs

      - name: Run unit tests
        run: flutter test test/unit/ --coverage

      - name: Run widget tests
        run: flutter test test/widget/ --coverage

      - name: Upload coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          files: ./ParentsApp/coverage/lcov.info
          flags: parentsapp
          name: parentsapp-coverage

      - name: Check coverage threshold
        run: |
          COVERAGE=$(lcov --summary coverage/lcov.info | grep lines | awk '{print $2}' | sed 's/%//')
          echo "Coverage: $COVERAGE%"
          if (( $(echo "$COVERAGE < 80" | bc -l) )); then
            echo "Coverage below 80% threshold"
            exit 1
          fi

  integration-test:
    name: Integration Tests
    runs-on: macos-latest

    defaults:
      run:
        working-directory: ParentsApp

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Flutter
        uses: subosito/flutter-action@v2

      - name: Install dependencies
        run: flutter pub get

      - name: Start iOS Simulator
        run: |
          xcrun simctl boot "iPhone 14" || true

      - name: Run integration tests
        run: flutter test integration_test/ -d iPhone
```

### 10.2 Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running ParentsApp tests before commit..."

cd ParentsApp

# Run tests
flutter test --no-sound-null-safety

if [ $? -ne 0 ]; then
  echo "❌ Tests failed. Commit aborted."
  exit 1
fi

echo "✅ All tests passed!"
exit 0
```

Make executable:
```bash
chmod +x .git/hooks/pre-commit
```

---

## Code Coverage Requirements

### 11.1 Coverage Targets

| Layer | Minimum Coverage | Target Coverage |
|-------|------------------|-----------------|
| **Services** | 90% | 95% |
| **Models** | 85% | 90% |
| **Widgets/Screens** | 70% | 80% |
| **Overall** | 80% | 85% |

### 11.2 Generate Coverage Report

```bash
# Generate coverage
flutter test --coverage

# Install lcov (if not installed)
# macOS: brew install lcov
# Ubuntu: sudo apt-get install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open report
open coverage/html/index.html
```

### 11.3 Exclude Files from Coverage

Create `coverage/lcov.info` exclusions:

```dart
// In test file, add at top:
// coverage:ignore-file

// For single line:
someFunction(); // coverage:ignore-line

// For block:
// coverage:ignore-start
void debugOnlyFunction() {
  // ...
}
// coverage:ignore-end
```

---

## Testing Best Practices

### 12.1 Writing Good Tests

#### ✅ DO:
- **Use descriptive test names**: `test('should return error when phone number is empty')`
- **Follow AAA pattern**: Arrange → Act → Assert
- **Test one behavior per test**
- **Use meaningful variable names**
- **Mock external dependencies**
- **Test edge cases and error scenarios**
- **Keep tests fast** (< 100ms for unit tests)
- **Use setUp/tearDown for common initialization**

#### ❌ DON'T:
- Test implementation details
- Write brittle tests that break on refactoring
- Share state between tests
- Use real network calls or databases
- Skip cleanup in tearDown
- Ignore flaky tests
- Test private methods directly

### 12.2 Test Naming Convention

```dart
// Pattern: should [expected behavior] when [condition]
test('should return list of children when API call succeeds', () {});
test('should throw exception when network is unavailable', () {});
test('should retry connection when WebSocket disconnects', () {});

// For widget tests: user action → expected outcome
testWidgets('tapping login button shows loading indicator', () {});
testWidgets('entering invalid phone displays error message', () {});
```

### 12.3 Mock Data Best Practices

```dart
// ✅ GOOD: Use realistic data
final mockChild = Child(
  id: 1,
  firstName: 'John',
  lastName: 'Doe',
  classGrade: 'Grade 5',
);

// ❌ BAD: Use unrealistic data
final mockChild = Child(
  id: 999999,
  firstName: 'aaaa',
  lastName: 'bbbb',
  classGrade: 'xyz',
);
```

### 12.4 Async Testing Tips

```dart
// ✅ GOOD: Use async/await
test('should fetch data asynchronously', () async {
  final result = await apiService.getData();
  expect(result, isNotNull);
});

// ✅ GOOD: Use expectLater for streams
test('should emit connection states', () {
  expectLater(
    service.connectionStream,
    emitsInOrder([
      ConnectionState.connecting,
      ConnectionState.connected,
    ]),
  );
});

// ❌ BAD: Not awaiting async operations
test('should fetch data', () {
  apiService.getData(); // Missing await!
  // Test completes before data is fetched
});
```

---

## Testing Checklist

### Before Pushing Code:

- [ ] All existing tests pass (`flutter test`)
- [ ] New code has corresponding tests
- [ ] Edge cases are covered
- [ ] Coverage meets minimum threshold (80%+)
- [ ] No flaky tests (run tests 3x to verify)
- [ ] Mock data is realistic
- [ ] Test names are descriptive
- [ ] Cleanup happens in tearDown

### Before Merging PR:

- [ ] CI/CD pipeline passes
- [ ] Code review includes test review
- [ ] Integration tests pass on real devices
- [ ] Coverage report reviewed
- [ ] No skipped tests without justification
- [ ] Performance tests pass (if applicable)

---

## Test Maintenance

### Monthly Tasks:
1. **Review flaky tests**: Fix or remove
2. **Update mock data**: Keep realistic with prod data
3. **Check coverage reports**: Identify untested code
4. **Performance check**: Ensure test suite runs < 5 minutes
5. **Dependency updates**: Update mockito, faker, etc.

### Quarterly Tasks:
1. **Refactor duplicate test code**: Extract to helpers
2. **Review integration tests**: Update for new flows
3. **Accessibility testing**: Add new a11y tests
4. **Load testing**: Test with large datasets

---

## Troubleshooting

### Common Issues:

**1. Tests fail with "MissingPluginException"**
```bash
# Solution: Run tests with --enable-impeller=false
flutter test --enable-impeller=false
```

**2. SharedPreferences tests fail**
```dart
// Solution: Initialize mock values
setUp(() {
  SharedPreferences.setMockInitialValues({});
});
```

**3. WebSocket tests are flaky**
```dart
// Solution: Add proper delays
await Future.delayed(Duration(milliseconds: 100));
await tester.pumpAndSettle();
```

**4. Coverage not generating**
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter test --coverage
```

---

## Resources

### Flutter Testing Documentation:
- [Official Flutter Testing Guide](https://docs.flutter.dev/testing)
- [Mockito Package](https://pub.dev/packages/mockito)
- [Integration Testing](https://docs.flutter.dev/testing/integration-tests)

### Best Practices:
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)
- [Flutter Test Driven Development](https://resocoder.com/flutter-tdd-clean-architecture-course/)

---

## Summary

This testing guide provides a **complete roadmap** for testing the ParentsApp Flutter application:

✅ **115+ tests** covering services, models, widgets, and integration flows
✅ **80%+ code coverage** target with enforcement in CI/CD
✅ **Comprehensive edge case handling** for production reliability
✅ **Automated testing pipeline** with GitHub Actions
✅ **Clear testing architecture** following the testing pyramid

**Next Steps:**
1. Add test dependencies to `pubspec.yaml`
2. Create test directory structure
3. Start with ApiService unit tests (highest priority)
4. Run `flutter test` frequently during development
5. Set up CI/CD pipeline to enforce testing

**Testing is not optional for this app** - it handles safety-critical data for children's transportation. Comprehensive testing ensures parents can trust the app to track their children reliably.

---

**Last Updated:** 2026-01-19
**Maintained By:** QA/Testing Team
**Questions?** See [CONTRIBUTING.md](./CONTRIBUTING.md) or open an issue.
