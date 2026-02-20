import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';

/// Authentication Service for Driver Magic Link Flow
///
/// Handles the complete authentication flow:
/// 1. Send magic link email via Supabase
/// 2. Listen for deep link callback when driver clicks link
/// 3. Exchange Supabase token for Django JWT tokens
/// 4. Store tokens and driver/bus/route data
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  StreamSubscription<AuthState>? _authSubscription;

  /// Helper method to save driver data to SharedPreferences
  /// Avoids code duplication across different login methods
  Future<void> _saveDriverDataToPrefs(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // Store tokens
    await prefs.setString('access_token', data['tokens']['access']);
    await prefs.setString('refresh_token', data['tokens']['refresh']);

    // Store driver info - parse user_id to int (API may return as String)
    final userId = data['user_id'];
    final userIdInt = userId is int ? userId : int.parse(userId.toString());

    // New unified keys used across the app
    await prefs.setInt('user_id', userIdInt);
    await prefs.setString('user_name', data['name'] ?? '');
    await prefs.setString('user_email', data['email'] ?? '');
    await prefs.setString('user_phone', data['phone'] ?? '');
    await prefs.setString('user_role', data['user_type'] ?? 'driver');

    // Backwards‑compatible driver-specific keys used by some older screens
    await prefs.setInt('driver_id', userIdInt);
    await prefs.setInt('user_id', userIdInt);
    await prefs.setString('driver_name', data['name'] ?? '');
    await prefs.setString('user_name', data['name'] ?? '');  // dashboard reads this key
    await prefs.setString('user_role', 'driver');
    await prefs.setString('driver_email', data['email'] ?? '');
    await prefs.setString('driver_phone', data['phone'] ?? '');
    await prefs.setString('license_number', data['license_number'] ?? '');
    await prefs.setString('license_expiry', data['license_expiry'] ?? '');
  }

  /// Phone-based login for drivers and bus minders (passwordless)
  ///
  /// Unified endpoint that automatically detects user type.
  /// Returns Django JWT tokens and user/bus/route data.
  ///
  /// Returns:
  /// - Map with 'success', 'message', and optional 'result' (AuthResult) keys
  Future<Map<String, dynamic>> loginWithPhone(String phoneNumber) async {
    try {
      final response = await _dio.post(
        '/api/auth/phone-login/',
        data: {'phone_number': phoneNumber},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save driver data using helper method
        await _saveDriverDataToPrefs(data);

        return {
          'success': true,
          'message': 'Login successful',
          'result': AuthResult(
            success: true,
            driver: {
              'user_id': data['user_id'],
              'name': data['name'],
              'email': data['email'],
              'phone': data['phone'],
              'license_number': data['license_number'],
              'license_expiry': data['license_expiry'],
            },
            bus: data['bus'],
            route: data['route'],
            tokens: data['tokens'],
          ),
        };
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Login failed',
        };
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': false,
          'message': e.response?.data['error'] ??
              'No driver or bus assistant account found with this phone number. Please contact your administrator.',
        };
      } else if (e.response?.statusCode == 400) {
        return {
          'success': false,
          'message':
              e.response?.data['error'] ?? 'Invalid phone number format.',
        };
      } else if (e.response?.statusCode == 403) {
        return {
          'success': false,
          'message': e.response?.data['error'] ??
              'Account is inactive. Please contact your administrator.',
        };
      }
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } on FormatException catch (e) {
      return {
        'success': false,
        'message':
            'Invalid data format received from server. Please contact your administrator.',
      };
    } on TypeError catch (e) {
      return {
        'success': false,
        'message': 'Data type error. Please contact your administrator.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Login failed: ${e.toString()}',
      };
    }
  }

  /// Send magic link to driver email
  ///
  /// First checks if email is registered in Django backend,
  /// then sends magic link via Supabase.
  ///
  /// Returns:
  /// - Map with 'success' and 'message' keys
  Future<Map<String, dynamic>> sendMagicLink(String email) async {
    try {
      // Step 1: Check if email is registered in Django
      final checkResponse = await _dio.post(
        '/api/drivers/auth/check-email/',
        data: {'email': email},
      );

      if (checkResponse.statusCode != 200) {
        // Email not registered
        return {
          'success': false,
          'message': checkResponse.data['message'] ??
              'This email is not registered. Please contact your administrator.',
        };
      }

      // Step 2: Email is registered, send magic link via Supabase
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );

      return {
        'success': true,
        'message': 'Magic link sent to your email',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {
          'success': false,
          'message': e.response?.data['message'] ??
              'This email is not registered. Please contact your administrator.',
        };
      }
      return {
        'success': false,
        'message': 'Connection error. Please check your internet connection.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send magic link. Please try again.',
      };
    }
  }

  /// Listen for authentication state changes (magic link callback)
  ///
  /// When driver clicks magic link and app opens:
  /// 1. Supabase automatically handles the deep link
  /// 2. Auth state changes to authenticated
  /// 3. We extract the access token
  /// 4. Exchange it for Django JWT tokens
  ///
  /// Returns Stream<AuthResult> with authentication status
  Stream<AuthResult> listenForAuthCallback() {
    final controller = StreamController<AuthResult>();

    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (authState) async {
        final session = authState.session;

        if (session != null) {
          // Driver authenticated via magic link - exchange for Django tokens
          final accessToken = session.accessToken;

          try {
            final result = await _exchangeTokenForDjangoAuth(accessToken);
            controller.add(result);
          } catch (e) {
            controller.add(AuthResult(
              success: false,
              error: 'Failed to complete authentication: ${e.toString()}',
            ));
          }
        }
      },
      onError: (error) {
        // Handle Supabase auth errors (expired links, invalid tokens, etc.)
        String errorMessage = 'Authentication failed';

        if (error.toString().contains('otp_expired') ||
            error.toString().contains('expired')) {
          errorMessage = 'Magic link has expired. Please request a new one.';
        } else if (error.toString().contains('invalid')) {
          errorMessage = 'Invalid magic link. Please request a new one.';
        }

        controller.add(AuthResult(
          success: false,
          error: errorMessage,
        ));
      },
    );

    return controller.stream;
  }

  /// Exchange Supabase access token for Django JWT tokens
  Future<AuthResult> _exchangeTokenForDjangoAuth(String supabaseToken) async {
    try {
      final response = await _dio.post(
        '/api/drivers/auth/magic-link/',
        data: {'access_token': supabaseToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save driver data using helper method
        await _saveDriverDataToPrefs(data);

        return AuthResult(
          success: true,
          driver: {
            'user_id': data['user_id'],
            'name': data['name'],
            'email': data['email'],
            'phone': data['phone'],
            'license_number': data['license_number'],
            'license_expiry': data['license_expiry'],
          },
          bus: data['bus'],
          route: data['route'],
          tokens: data['tokens'],
        );
      } else {
        return AuthResult(
          success: false,
          error: response.data['message'] ?? 'Authentication failed',
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Authentication failed';

      if (e.response?.statusCode == 404) {
        errorMessage = e.response?.data['message'] ??
            'No driver account found. Please contact your administrator.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = e.response?.data['message'] ??
            'Session expired. Please request a new magic link.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage =
            'Connection timeout. Please check your internet connection.';
      }

      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Check if driver is currently authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    return accessToken != null && accessToken.isNotEmpty;
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get stored refresh token
  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  /// Refresh access token using refresh token
  /// Returns new access token if successful, null otherwise
  Future<String?> refreshAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        return null;
      }

      final response = await _dio.post(
        '/api/token/refresh/',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.data['access'];

        // Store new access token
        await prefs.setString('access_token', newAccessToken);

        // If a new refresh token is provided, update it too
        if (response.data['refresh'] != null) {
          await prefs.setString('refresh_token', response.data['refresh']);
        }

        return newAccessToken;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sign out driver
  Future<void> signOut() async {
    // Sign out from Supabase
    await _supabase.auth.signOut();

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('driver_id');
    await prefs.remove('user_id');
    await prefs.remove('driver_name');
    await prefs.remove('driver_email');
    await prefs.remove('driver_phone');
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Result of driver authentication attempt
class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? driver;
  final Map<String, dynamic>? bus;
  final Map<String, dynamic>? route;
  final Map<String, dynamic>? tokens;

  AuthResult({
    required this.success,
    this.error,
    this.driver,
    this.bus,
    this.route,
    this.tokens,
  });
}
