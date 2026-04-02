import 'dart:async';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';
import '../data/user_session.dart';
import 'app_store.dart';

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

  // Tracks whether the last check-email call identified a driver or busminder.
  String _pendingUserType = 'driver';

  /// Persist session data to [AppStore] and flat token keys.
  Future<void> _saveDriverDataToPrefs(Map<String, dynamic> data) async {
    await AppStore.instance.saveUser(UserSession.fromApiResponse(data));
    // Keep flat token keys so the HTTP interceptor can read them without AppStore.
    final prefs = await SharedPreferences.getInstance();
    final tokens = data['tokens'] as Map<String, dynamic>?;
    if (tokens != null) {
      await prefs.setString('access_token', tokens['access'] as String? ?? '');
      await prefs.setString('refresh_token', tokens['refresh'] as String? ?? '');
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
    // Reviewer demo account must use the password flow, not magic link
    if (isReviewerAccount(email)) {
      return {
        'success': false,
        'message': 'Please enter your password to sign in.',
      };
    }

    try {
      // Step 1: Check if email is registered as a driver or busminder
      bool registered = false;
      try {
        final driverCheck = await _dio.post(
          '/api/drivers/auth/check-email/',
          data: {'email': email},
        );
        if (driverCheck.statusCode == 200) {
          registered = true;
          _pendingUserType = 'driver';
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          // Not a driver — try busminder
          try {
            final busminderCheck = await _dio.post(
              '/api/busminders/auth/check-email/',
              data: {'email': email},
            );
            if (busminderCheck.statusCode == 200) {
              registered = true;
              _pendingUserType = 'busminder';
            }
          } on DioException {
            registered = false;
          }
        } else {
          rethrow;
        }
      }

      if (!registered) {
        return {
          'success': false,
          'message': 'This email is not registered. Please contact your administrator.',
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
      final msg = e.toString();
      if (msg.contains('over_email_send_rate_limit') || msg.contains('rate limit')) {
        return {
          'success': false,
          'message': 'Too many login attempts. Please wait a few minutes and try again.',
        };
      }
      if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
        return {
          'success': false,
          'message': 'Please check your email and confirm your account first.',
        };
      }
      return {
        'success': false,
        'message': 'Failed to send login link. Please check your connection and try again.',
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
    // Try the expected endpoint first, fall back to the other role.
    // This handles deep-link cold starts where _pendingUserType resets to default.
    final primaryEndpoint = _pendingUserType == 'busminder'
        ? '/api/busminders/auth/magic-link/'
        : '/api/drivers/auth/magic-link/';
    final fallbackEndpoint = _pendingUserType == 'busminder'
        ? '/api/drivers/auth/magic-link/'
        : '/api/busminders/auth/magic-link/';

    try {
      Response response;
      try {
        response = await _dio.post(primaryEndpoint, data: {'access_token': supabaseToken});
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
          response = await _dio.post(fallbackEndpoint, data: {'access_token': supabaseToken});
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200) {
        final data = response.data;

        // Save driver/busminder data using helper method
        await _saveDriverDataToPrefs(data);

        final isBusMinder = data['user_type'] == 'busminder';
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
          // For busminders, pack buses list into route so routing logic works.
          route: isBusMinder ? {'buses': data['buses']} : data['route'],
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

  static const String _reviewerDriverEmail = 'reviewer.driver@apobasi.com';
  static const String _reviewerMinderemail = 'reviewer.minder@apobasi.com';

  static bool isReviewerAccount(String email) {
    final e = email.trim().toLowerCase();
    return e == _reviewerDriverEmail || e == _reviewerMinderemail;
  }

  Future<AuthResult> loginWithPassword(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final endpoint = normalizedEmail == _reviewerMinderemail
        ? '/api/busminders/auth/demo-login/'
        : '/api/drivers/auth/demo-login/';
    try {
      final response = await _dio.post(
        endpoint,
        data: {'email': normalizedEmail, 'password': password},
      );

      if (response.statusCode == 200) {
        final data = response.data;
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
      }

      return AuthResult(
        success: false,
        error: response.data['error'] ?? response.data['message'] ?? 'Login failed',
      );
    } on DioException catch (e) {
      String msg = 'Login failed';
      if (e.response?.statusCode == 401) msg = 'Invalid email or password';
      if (e.response?.statusCode == 404) {
        msg = e.response?.data['message'] ?? 'Demo account not configured';
      }
      if (e.response?.statusCode == 503) msg = 'Demo login not available';
      return AuthResult(success: false, error: msg);
    } catch (e) {
      return AuthResult(success: false, error: 'Unexpected error: $e');
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
    // 1. Clear ALL local state immediately — prefs.clear() is synchronous/local,
    //    so this is fast and removes every key written anywhere in the app.
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    // 2. Revoke the Supabase session server-side — fire-and-forget so the UI
    //    never waits on a network call. Errors are silently swallowed.
    _supabase.auth.signOut().catchError((_) {});
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
