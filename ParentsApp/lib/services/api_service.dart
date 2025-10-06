import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_model.dart';
import '../models/parent_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // Android emulator localhost
  // Use 'http://localhost:8000' for iOS simulator
  // Use your computer's IP for physical device (e.g., 'http://192.168.1.100:8000')

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
    await prefs.remove('children_data');
  }

  // Phone login
  Future<Map<String, dynamic>> phoneLogin(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post(
        '/api/parents/phone-login/',
        data: {
          'phone_number': phoneNumber,
          'otp': otp,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save tokens
        await _saveToken(data['tokens']['access']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('refresh_token', data['tokens']['refresh']);

        // Save user and children data
        await prefs.setString('user_data', data['user'].toString());
        await prefs.setString('children_data', data['children'].toString());

        return data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Login failed');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Get parent's children
  Future<List<Child>> getMyChildren() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/parents/my-children/');

      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> childrenJson = data['children'];
        return childrenJson.map((json) => Child.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load children');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ?? 'Failed to load children');
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
}
