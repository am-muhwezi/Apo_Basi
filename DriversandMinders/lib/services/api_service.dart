import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // DEVELOPMENT: Use WiFi IP for testing on physical device
  // TODO: Update this to match your backend server IP/domain
  static const String baseUrl = 'http://192.168.100.36:8000';

  // OTHER OPTIONS:
  // Android emulator: 'http://10.0.2.2:8000'
  // iOS simulator: 'http://localhost:8000'
  // Production: 'http://YOUR_VPS_IP' or 'https://yourdomain.com'

  late Dio _dio;
  String? _accessToken;

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add token to requests if available
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    ));
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

  // TODO: BACKEND IMPLEMENTATION NEEDED
  // Phone-based login for drivers (passwordless, similar to parent phone login)
  // The backend needs to implement: POST /api/drivers/phone-login/
  // Expected request body: {"phone_number": "0773882123"}
  // Expected response: {"user": {...}, "tokens": {...}, "driver": {...}, "bus": {...}}
  Future<Map<String, dynamic>> driverPhoneLogin(String phoneNumber) async {
    try {
      // TODO: Replace this endpoint when backend implements phone-login
      // For now, trying to login by searching for driver with this phone number
      // TEMPORARY: Uses username/password login as fallback

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

        return data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Phone number not found.');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
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
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Phone number not found.');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Get driver's assigned bus and children
  // Backend endpoint: GET /api/drivers/my-bus/
  Future<Map<String, dynamic>> getDriverBus() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/drivers/my-bus/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load bus information');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to load bus information');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Get driver's route details with children
  // Backend endpoint: GET /api/drivers/my-route/
  Future<Map<String, dynamic>> getDriverRoute() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/drivers/my-route/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load route information');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to load route information');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Get bus minder's assigned buses
  // Backend endpoint: GET /api/busminders/my-buses/
  Future<Map<String, dynamic>> getBusMinderBuses() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/busminders/my-buses/');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to load buses information');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to load buses information');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Get children for a specific bus (for bus minders)
  // Backend endpoint: GET /api/busminders/buses/{bus_id}/children/
  Future<List<dynamic>> getBusChildren(int busId) async {
    try {
      await loadToken();
      final response = await _dio.get('/api/busminders/buses/$busId/children/');

      if (response.statusCode == 200) {
        return response.data['children'] ?? [];
      } else {
        throw Exception('Failed to load children information');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to load children information');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Mark attendance for a child (for bus minders)
  // Backend endpoint: POST /api/busminders/mark-attendance/
  Future<Map<String, dynamic>> markAttendance({
    required int childId,
    required String status,
    String? notes,
  }) async {
    try {
      await loadToken();
      final response = await _dio.post(
        '/api/busminders/mark-attendance/',
        data: {
          'child_id': childId,
          'status': status,
          'notes': notes,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception('Failed to mark attendance');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to mark attendance');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
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
}
