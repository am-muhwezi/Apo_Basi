import 'dart:async';
import 'package:dio/dio.dart';
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

  /// Send magic link to email
  ///
  /// Returns:
  /// - true if email sent successfully
  /// - false if error occurred
  Future<bool> sendMagicLink(String email) async {
    try {
      await _supabase.auth.signInWithOtp(
        email: email,
        emailRedirectTo: SupabaseConfig.redirectUrl,
      );
      return true;
    } catch (e) {
      return false;
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

    _authSubscription = _supabase.auth.onAuthStateChange.listen((authState) async {
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
    });

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
