import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child_model.dart';
import '../models/parent_model.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class ApiService {
  late Dio _dio;
  String? _accessToken;
  final AuthService _authService = AuthService();
  bool _isRefreshing = false;

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
        // Add token to requests if available
        if (_accessToken != null) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 errors by attempting to refresh the token
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;

          try {
            // Attempt to refresh the access token
            final newAccessToken = await _authService.refreshAccessToken();

            if (newAccessToken != null) {
              // Update the token
              _accessToken = newAccessToken;

              // Retry the original request with the new token
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $newAccessToken';

              _isRefreshing = false;

              // Retry the request
              try {
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              // Refresh failed, clear tokens and force re-login
              await clearToken();
              _isRefreshing = false;
              return handler.next(error);
            }
          } catch (e) {
            _isRefreshing = false;
            return handler.next(error);
          }
        }

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
    await prefs.remove('children_data');
  }

  // Direct phone login (no OTP)
  Future<Map<String, dynamic>> directPhoneLogin(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/api/parents/login/',
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

        // Save user ID for profile access - parent object contains the user id
        if (data['parent'] != null && data['parent']['id'] != null) {
          await _saveUserId(int.parse(data['parent']['id'].toString()));
        }

        // Save user and children data (handle null safely)
        if (data['parent'] != null) {
          await prefs.setString('user_data', data['parent'].toString());
        }
        if (data['children'] != null) {
          await prefs.setString('children_data', data['children'].toString());
        }

        return data;
      } else {
        throw Exception('Login failed');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Login failed. Please try again.'),
      );
    }
  }

  // Get parent's children
  Future<List<Child>> getMyChildren() async {
    try {
      await loadToken();

      // Get saved user ID
      final userId = await _getSavedUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login again.');
      }

      final response = await _dio.get('/api/parents/$userId/children/');

      if (response.statusCode == 200) {
        final data = response.data;
        // Handle null or missing children array
        final List<dynamic>? childrenJson = data['children'];

        if (childrenJson == null || childrenJson.isEmpty) {
          return []; // Return empty list if no children
        }

        return childrenJson.map((json) => Child.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load children');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load children'),
      );
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('access_token');
  }

  // Get saved user ID from preferences
  Future<int?> _getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('user_id');
  }

  // Save user ID to preferences
  Future<void> _saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', userId);
  }

  // Get parent profile using stored user_id
  Future<Map<String, dynamic>> getParentProfile() async {
    try {
      await loadToken();

      // Get saved user ID
      final userId = await _getSavedUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login again.');
      }

      final response = await _dio.get('/api/parents/$userId/');

      if (response.statusCode == 200) {
        final data = response.data;

        // Return in a format that matches what the app expects
        return {
          'user': {
            'id': data['id'] ?? userId,
            'username': data['firstName'] ?? '',
            'email': data['email'] ?? '',
            'first_name': data['firstName'] ?? '',
            'last_name': data['lastName'] ?? '',
          },
          'parent': {
            'user': data['id'] ?? userId,
            'contact_number': data['phone'] ?? '',
            'address': data['address'] ?? '',
            'emergency_contact': data['emergencyContact'] ?? '',
            'status': data['status'] ?? 'active',
          }
        };
      } else {
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to load profile'),
      );
    }
  }

  // Update parent profile
  Future<Map<String, dynamic>> updateParentProfile({
    String? address,
    String? emergencyContact,
  }) async {
    try {
      await loadToken();

      // Get saved user ID
      final userId = await _getSavedUserId();
      if (userId == null) {
        throw Exception('User not logged in. Please login again.');
      }

      // Prepare data with camelCase keys for backend
      final data = <String, dynamic>{};
      if (address != null) data['address'] = address;
      if (emergencyContact != null) data['emergencyContact'] = emergencyContact;

      final response = await _dio.patch('/api/parents/$userId/', data: data);

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Failed to update profile');
      }
    } on DioException catch (e) {
      throw Exception(
        _extractErrorMessage(e, 'Failed to update profile'),
      );
    }
  }

  // Get all notifications for the logged-in parent
  Future<dynamic> getNotifications({
    bool? isRead,
    String? type,
    int limit = 50,
  }) async {
    try {
      await loadToken();

      final queryParams = <String, dynamic>{
        'limit': limit.toString(),
      };

      if (isRead != null) {
        queryParams['is_read'] = isRead.toString();
      }

      if (type != null) {
        queryParams['type'] = type;
      }

      final response = await _dio.get(
        '/api/notifications/',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        return response.data; // Can be List or Map
      } else {
        throw Exception('Failed to load notifications');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to load notifications');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Mark notifications as read
  Future<Map<String, dynamic>> markNotificationsAsRead({
    List<int>? notificationIds,
  }) async {
    try {
      await loadToken();

      // If specific IDs provided, mark those
      if (notificationIds != null && notificationIds.isNotEmpty) {
        // Mark individual notifications
        for (final id in notificationIds) {
          await _dio.post('/api/notifications/$id/mark-read/');
        }
        return {
          'message': 'Notifications marked as read',
          'count': notificationIds.length
        };
      } else {
        // Mark all as read
        final response = await _dio.post('/api/notifications/mark-all-read/');

        if (response.statusCode == 200) {
          return response.data;
        } else {
          throw Exception('Failed to mark notifications as read');
        }
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['error'] ??
            'Failed to mark notifications as read');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }

  // Delete a specific notification
  Future<void> deleteNotification(int notificationId) async {
    try {
      await loadToken();

      final response = await _dio.delete(
        '/api/notifications/$notificationId/',
      );

      if (response.statusCode != 204 && response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(
            e.response?.data['error'] ?? 'Failed to delete notification');
      } else {
        throw Exception('Network error. Please check your connection.');
      }
    }
  }
}
