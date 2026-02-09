import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/api_config.dart';
import '../config/supabase_config.dart';

/// Authentication Service for Magic Link Flow
///
/// Handles the complete authentication flow:
/// 1. Send magic link email via Supabase
/// 2. Listen for deep link callback when user clicks link
/// 3. Exchange Supabase token for Django JWT tokens
/// 4. Store tokens and parent/children data
///
/// Also supports demo account for Apple App Store Review
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Demo account credentials from environment
  String get _reviewerEmail => dotenv.env['REVIEWER_EMAIL'] ?? '';
  String get _reviewerPassword => dotenv.env['REVIEWER_PASSWORD'] ?? '';

  /// Check if email is the Apple reviewer demo account
  bool isReviewerAccount(String email) {
    final reviewerEmail = _reviewerEmail;
    if (reviewerEmail.isEmpty) return false;
    return email.trim().toLowerCase() == reviewerEmail.toLowerCase();
  }
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  StreamSubscription<AuthState>? _authSubscription;

  /// Authenticate demo/reviewer account with password
  ///
  /// Used for Apple App Store review process.
  /// Returns AuthResult with demo data on success.
  Future<AuthResult> loginWithPassword(String email, String password) async {
    // Validate credentials
    if (email.trim().toLowerCase() != _reviewerEmail.toLowerCase() ||
        password != _reviewerPassword) {
      return AuthResult(
        success: false,
        error: 'Invalid email or password',
      );
    }

    try {
      // Call backend demo login endpoint
      final response = await _dio.post(
        '/api/parents/auth/demo-login/',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Store Django JWT tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['tokens']['access']);
        await prefs.setString('refresh_token', data['tokens']['refresh']);

        // Store parent info
        await prefs.setInt('parent_id', data['parent']['id']);
        await prefs.setString('parent_first_name', data['parent']['firstName']);
        await prefs.setString('parent_last_name', data['parent']['lastName']);
        await prefs.setString('parent_email', data['parent']['email']);

        return AuthResult(
          success: true,
          parent: data['parent'],
          children: data['children'],
          tokens: data['tokens'],
        );
      } else {
        return AuthResult(
          success: false,
          error: response.data['message'] ?? 'Demo login failed',
        );
      }
    } on DioException catch (e) {
      return AuthResult(
        success: false,
        error: e.response?.data['message'] ?? 'Connection error. Please try again.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Demo login failed: ${e.toString()}',
      );
    }
  }

  /// Send magic link to email
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
        '/api/parents/auth/check-email/',
        data: {'email': email},
      );

      if (checkResponse.statusCode != 200) {
        // Email not registered
        return {
          'success': false,
          'message': checkResponse.data['message'] ??
              'This email is not registered. Please contact your school administrator.',
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
              'This email is not registered. Please contact your school administrator.',
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
  /// When user clicks magic link and app opens:
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
          // User authenticated via magic link - exchange for Django tokens
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
        '/api/parents/auth/magic-link/',
        data: {'access_token': supabaseToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Store Django JWT tokens
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', data['tokens']['access']);
        await prefs.setString('refresh_token', data['tokens']['refresh']);

        // Store parent info
        await prefs.setInt('parent_id', data['parent']['id']);
        await prefs.setString('parent_first_name', data['parent']['firstName']);
        await prefs.setString('parent_last_name', data['parent']['lastName']);
        await prefs.setString('parent_email', data['parent']['email']);

        return AuthResult(
          success: true,
          parent: data['parent'],
          children: data['children'],
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
            'No parent account found. Please contact your school administrator.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = e.response?.data['message'] ??
            'Session expired. Please request a new magic link.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      }

      return AuthResult(success: false, error: errorMessage);
    } catch (e) {
      return AuthResult(
        success: false,
        error: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Check if user is currently authenticated (has valid tokens)
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

  /// Sign out user
  Future<void> signOut() async {
    // Sign out from Supabase
    await _supabase.auth.signOut();

    // Clear local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('parent_id');
    await prefs.remove('parent_first_name');
    await prefs.remove('parent_last_name');
    await prefs.remove('parent_email');
  }

  /// Dispose resources
  void dispose() {
    _authSubscription?.cancel();
  }
}

/// Result of authentication attempt
class AuthResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? parent;
  final List<dynamic>? children;
  final Map<String, dynamic>? tokens;

  AuthResult({
    required this.success,
    this.error,
    this.parent,
    this.children,
    this.tokens,
  });
}
