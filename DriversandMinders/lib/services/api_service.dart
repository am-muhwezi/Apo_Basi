import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiService {
  late Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Skip authentication for login endpoints
        final isLoginEndpoint = options.path.contains('/phone-login/') ||
            options.path.contains('/login/');

        if (!isLoginEndpoint) {
          // Load and add token for authenticated requests
          await loadToken();
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        if (error.response != null) {}
        return handler.next(error);
      },
    ));
  }

  String _extractErrorMessage(DioException e, String fallback) {
    final response = e.response;
    final data = response?.data;

    if (data is Map<String, dynamic>) {
      if (data['detail'] is String) return data['detail'] as String;

      final error = data['error'];
      if (error is String) return error;
      if (error is Map) {
        if (error['message'] is String) return error['message'] as String;
        final first = error.values.firstWhere(
          (v) => v is String,
          orElse: () => null,
        );
        if (first is String) return first;
      }

      if (data['message'] is String) return data['message'] as String;
    }

    if (e.message != null && e.message!.isNotEmpty) {
      return e.message!;
    }

    return fallback;
  }

  // Save token to shared preferences
  Future<void> _saveToken(String token) async {
    _accessToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  // Load token from shared preferences
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
  }

  // Clear token (logout)
  Future<void> clearToken() async {
    _accessToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('user_id');
    await prefs.remove('user_role');
    await prefs.remove('user_name');
    await prefs.remove('is_logged_in');
  }

  // Save user ID to preferences
  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  // Get saved user ID from preferences
  Future<int?> _getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Phone-based login for drivers (passwordless)
  // Returns user, tokens, bus, and route in a single response
  Future<Map<String, dynamic>> driverPhoneLogin(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/api/drivers/phone-login/',
        data: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await _saveToken(data['tokens']['access']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', data['tokens']['refresh']);

        // Save user data
        await _saveUserId(data['user_id']);

        await prefs.setString('user_role', 'driver');
        await prefs.setString('user_name', data['name']);
        await prefs.setString('user_phone', data['phone']);
        await prefs.setBool('is_logged_in', true);

        // Store license number and expiry if present
        if (data.containsKey('license_number') &&
            data['license_number'] != null) {
          await prefs.setString(
              'license_number', data['license_number'].toString());
        }
        if (data.containsKey('license_expiry') &&
            data['license_expiry'] != null) {
          await prefs.setString(
              'license_expiry', data['license_expiry'].toString());
        }
        if (data.containsKey('email') && data['email'] != null) {
          // Store under user_email to match profile screens
          await prefs.setString('user_email', data['email'].toString());
        }

        // Save bus ID if available
        if (data['bus'] != null && data['bus']['id'] != null) {
          await prefs.setInt('current_bus_id', data['bus']['id']);
        }

        return data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Phone number not found.'),
      );
    }
  }

  // TODO: BACKEND IMPLEMENTATION NEEDED
  // Direct ID login for bus minders (passwordless, similar to parent phone login)
  // The backend needs to implement: POST /api/busminders/direct-id-login/
  // Expected request body: {"staff_id": "S1234"} or {"phone_number": "1234567890"}
  // Expected response: {"user": {...}, "tokens": {...}, "busminder": {...}, "buses": [...]}
  Future<Map<String, dynamic>> busMinderPhoneLogin(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/api/busminders/phone-login/',
        data: {
          'phone_number': phoneNumber,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await _saveToken(data['tokens']['access']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', data['tokens']['refresh']);

        // Save user data
        await _saveUserId(data['user_id']);
        await prefs.setString('user_role', 'busminder');
        await prefs.setString('user_name', data['name']);
        await prefs.setString('user_phone', data['phone']);
        await prefs.setBool('is_logged_in', true);

        return data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Phone number not found.'),
      );
    }
  }

  // Get driver's assigned bus and children
  // Backend endpoint: GET /api/drivers/my-bus/
  Future<Map<String, dynamic>> getDriverBus() async {
    try {
      final response = await _dio.get('/api/drivers/my-bus/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load bus information');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load bus information'),
      );
    }
  }

  // Get driver's route details with children
  // Backend endpoint: GET /api/drivers/my-route/
  Future<Map<String, dynamic>> getDriverRoute() async {
    try {
      final response = await _dio.get('/api/drivers/my-route/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load route information');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load route information'),
      );
    }
  }

  // Get bus minder's assigned buses
  // Backend endpoint: GET /api/busminders/my-buses/
  Future<Map<String, dynamic>> getBusMinderBuses() async {
    try {
      final response = await _dio.get('/api/busminders/my-buses/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load buses information');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load buses information'),
      );
    }
  }

  // Get current location for a specific bus
  // Backend endpoint: GET /api/buses/{bus_id}/current-location/
  Future<Map<String, dynamic>> getBusCurrentLocation(int busId) async {
    try {
      final response = await _dio.get('/api/buses/$busId/current-location/');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load current bus location');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load current bus location'),
      );
    }
  }

  // Get children for a specific bus (for bus minders)
  // Backend endpoint: GET /api/busminders/buses/{bus_id}/children/?trip_type=pickup|dropoff
  Future<List<dynamic>> getBusChildren(int busId, {String? tripType}) async {
    try {
      final Map<String, dynamic> queryParams =
          tripType != null ? {'trip_type': tripType} : {};
      final response = await _dio.get(
        '/api/busminders/buses/$busId/children/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data['children'] ?? [];
      } else {
        throw Exception('Failed to load children information');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load children information'),
      );
    }
  }

  // Mark attendance for a child (for bus minders)
  // Backend endpoint: POST /api/busminders/mark-attendance/
  Future<Map<String, dynamic>> markAttendance({
    required int childId,
    required String status,
    String? notes,
    String? tripType,
  }) async {
    try {
      // Use the unified attendance endpoint that works for both drivers and bus minders
      final response = await _dio.post(
        '/api/attendance/mark/',
        data: {
          'child_id': childId,
          'status': status,
          'notes': notes,
          'trip_type': tripType,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to mark attendance');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to mark attendance'),
      );
    }
  }

  /// Get today's attendance records for a specific bus and trip type.
  ///
  /// Backend endpoint: GET /api/attendance/
  /// Query params:
  /// - date (YYYY-MM-DD, defaults to today on backend)
  /// - bus_id
  /// - trip_type (pickup|dropoff)
  Future<List<dynamic>> getTodayAttendance({
    int? busId,
    String? tripType,
    DateTime? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      final filterDate = date ?? DateTime.now();
      queryParams['date'] =
          '${filterDate.year.toString().padLeft(4, '0')}-${filterDate.month.toString().padLeft(2, '0')}-${filterDate.day.toString().padLeft(2, '0')}';

      if (busId != null) {
        queryParams['bus_id'] = busId;
      }
      if (tripType != null) {
        queryParams['trip_type'] = tripType;
      }

      final response = await _dio.get(
        '/api/attendance/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is List) {
          return data;
        }
        return [];
      } else {
        throw Exception('Failed to load attendance');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load attendance'),
      );
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  // Get user role
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // ==================== Trip Management ====================

  // Complete a trip with attendance summary
  Future<Map<String, dynamic>> completeTrip({
    required int tripId,
    required int totalStudents,
    required int studentsCompleted,
    required int studentsAbsent,
    required int studentsPending,
  }) async {
    try {
      final response = await _dio.post(
        '/api/trips/$tripId/complete/',
        data: {
          'totalStudents': totalStudents,
          'studentsCompleted': studentsCompleted,
          'studentsAbsent': studentsAbsent,
          'studentsPending': studentsPending,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get trip history for current user
  Future<List<dynamic>> getTripHistory({
    String? status,
    String? tripType,
    int? busId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (tripType != null) queryParams['type'] = tripType;
      if (busId != null) queryParams['bus_id'] = busId;

      final response = await _dio.get(
        '/api/trips/',
        queryParameters: queryParams,
      );

      // Handle response - ensure it's a list
      if (response.data is List) {
        return response.data as List<dynamic>;
      } else {
        // If it's not a list, return empty list
        return [];
      }
    } catch (e) {
      return []; // Return empty list instead of rethrowing
    }
  }

  // Get specific trip details
  Future<Map<String, dynamic>> getTripDetails(int tripId) async {
    try {
      final response = await _dio.get('/api/trips/$tripId/');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // ==================== Driver Trip Management ====================

  // Start a new trip
  Future<Map<String, dynamic>> startTrip({String tripType = 'pickup'}) async {
    try {
      final response = await _dio.post(
        '/api/drivers/start-trip/',
        data: {
          'trip_type': tripType,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw Exception(_extractErrorMessage(e, 'Failed to start trip'));
    }
  }

  // End a trip
  Future<Map<String, dynamic>> endTrip({
    required int tripId,
    int? totalStudents,
    int? studentsCompleted,
    int? studentsAbsent,
    int? studentsPending,
  }) async {
    try {
      final response = await _dio.post(
        '/api/drivers/end-trip/$tripId/',
        data: {
          if (totalStudents != null) 'totalStudents': totalStudents,
          if (studentsCompleted != null) 'studentsCompleted': studentsCompleted,
          if (studentsAbsent != null) 'studentsAbsent': studentsAbsent,
          if (studentsPending != null) 'studentsPending': studentsPending,
        },
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // Get active trip for current driver
  Future<Map<String, dynamic>?> getActiveTrip() async {
    try {
      final response = await _dio.get('/api/drivers/active-trip/');
      if (response.data['trip'] != null) {
        return response.data['trip'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ==================== Location Tracking ====================

  // Push location update for trip
  Future<void> pushLocation({
    required int tripId,
    required double latitude,
    required double longitude,
    double? speed,
    double? heading,
  }) async {
    try {
      await _dio.post(
        '/api/trips/$tripId/update-location/',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (speed != null) 'speed': speed,
          if (heading != null) 'heading': heading,
        },
      );
    } catch (e) {
      rethrow;
    }
  }
}
