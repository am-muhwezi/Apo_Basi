import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Supabase Configuration for Drivers & Bus Assistants
///
/// Manages Supabase credentials for magic link authentication.
/// Credentials are loaded from .env file for security.
class SupabaseConfig {
  /// Supabase project URL
  static String get supabaseUrl {
    final url = dotenv.env['SUPABASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL not found in .env file');
    }
    return url;
  }

  /// Supabase publishable (anon) key
  /// Safe to use in client-side applications
  static String get supabasePublishableKey {
    final key = dotenv.env['SUPABASE_PUBLISHABLE_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('SUPABASE_PUBLISHABLE_KEY not found in .env file');
    }
    return key;
  }

  /// Deep link redirect URL for magic link callback
  /// This must match the URL configured in Supabase dashboard
  /// Using a different scheme than parent app for proper routing
  static const String redirectUrl = 'apobasi-drivers://auth-callback';
}
