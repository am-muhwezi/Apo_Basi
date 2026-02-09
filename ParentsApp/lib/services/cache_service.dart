import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for caching API responses with expiration timestamps
///
/// Provides cache-first strategy for offline support:
/// 1. Check cache first
/// 2. Return cached data if fresh
/// 3. Fetch from API in background
/// 4. Update cache with new data
class CacheService {
  static const String _dashboardDataKey = 'dashboard_data';
  static const String _dashboardTimestampKey = 'dashboard_timestamp';
  static const String _profileDataKey = 'profile_data';
  static const String _profileTimestampKey = 'profile_timestamp';
  static const String _childrenDataKey = 'children_data';
  static const String _childrenTimestampKey = 'children_timestamp';
  static const String _notificationsDataKey = 'notifications_data';
  static const String _notificationsTimestampKey = 'notifications_timestamp';

  // Cache expiration time (5 minutes)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// Check if cached data is still fresh
  bool _isCacheFresh(DateTime? timestamp) {
    if (timestamp == null) return false;
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    return difference < _cacheExpiration;
  }

  /// Get cached dashboard data
  Future<Map<String, dynamic>?> getCachedDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_dashboardDataKey);
      final timestampStr = prefs.getString(_dashboardTimestampKey);

      if (dataStr == null || timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (!_isCacheFresh(timestamp)) return null;

      return json.decode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached dashboard: $e');
      return null;
    }
  }

  /// Cache dashboard data
  Future<void> cacheDashboard(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dashboardDataKey, json.encode(data));
      await prefs.setString(_dashboardTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching dashboard: $e');
    }
  }

  /// Get cached profile data
  Future<Map<String, dynamic>?> getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_profileDataKey);
      final timestampStr = prefs.getString(_profileTimestampKey);

      if (dataStr == null || timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (!_isCacheFresh(timestamp)) return null;

      return json.decode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting cached profile: $e');
      return null;
    }
  }

  /// Cache profile data
  Future<void> cacheProfile(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_profileDataKey, json.encode(data));
      await prefs.setString(_profileTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching profile: $e');
    }
  }

  /// Get cached children data
  Future<List<dynamic>?> getCachedChildren() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_childrenDataKey);
      final timestampStr = prefs.getString(_childrenTimestampKey);

      if (dataStr == null || timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (!_isCacheFresh(timestamp)) return null;

      return json.decode(dataStr) as List<dynamic>;
    } catch (e) {
      print('Error getting cached children: $e');
      return null;
    }
  }

  /// Cache children data
  Future<void> cacheChildren(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_childrenDataKey, json.encode(data));
      await prefs.setString(_childrenTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching children: $e');
    }
  }

  /// Get cached notifications data
  Future<List<dynamic>?> getCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_notificationsDataKey);
      final timestampStr = prefs.getString(_notificationsTimestampKey);

      if (dataStr == null || timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      if (!_isCacheFresh(timestamp)) return null;

      return json.decode(dataStr) as List<dynamic>;
    } catch (e) {
      print('Error getting cached notifications: $e');
      return null;
    }
  }

  /// Cache notifications data
  Future<void> cacheNotifications(List<dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationsDataKey, json.encode(data));
      await prefs.setString(_notificationsTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('Error caching notifications: $e');
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_dashboardDataKey);
      await prefs.remove(_dashboardTimestampKey);
      await prefs.remove(_profileDataKey);
      await prefs.remove(_profileTimestampKey);
      await prefs.remove(_childrenDataKey);
      await prefs.remove(_childrenTimestampKey);
      await prefs.remove(_notificationsDataKey);
      await prefs.remove(_notificationsTimestampKey);
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check and clear dashboard cache if expired
      final dashboardTimestampStr = prefs.getString(_dashboardTimestampKey);
      if (dashboardTimestampStr != null) {
        final timestamp = DateTime.parse(dashboardTimestampStr);
        if (!_isCacheFresh(timestamp)) {
          await prefs.remove(_dashboardDataKey);
          await prefs.remove(_dashboardTimestampKey);
        }
      }

      // Check and clear profile cache if expired
      final profileTimestampStr = prefs.getString(_profileTimestampKey);
      if (profileTimestampStr != null) {
        final timestamp = DateTime.parse(profileTimestampStr);
        if (!_isCacheFresh(timestamp)) {
          await prefs.remove(_profileDataKey);
          await prefs.remove(_profileTimestampKey);
        }
      }

      // Check and clear children cache if expired
      final childrenTimestampStr = prefs.getString(_childrenTimestampKey);
      if (childrenTimestampStr != null) {
        final timestamp = DateTime.parse(childrenTimestampStr);
        if (!_isCacheFresh(timestamp)) {
          await prefs.remove(_childrenDataKey);
          await prefs.remove(_childrenTimestampKey);
        }
      }

      // Check and clear notifications cache if expired
      final notificationsTimestampStr = prefs.getString(_notificationsTimestampKey);
      if (notificationsTimestampStr != null) {
        final timestamp = DateTime.parse(notificationsTimestampStr);
        if (!_isCacheFresh(timestamp)) {
          await prefs.remove(_notificationsDataKey);
          await prefs.remove(_notificationsTimestampKey);
        }
      }
    } catch (e) {
      print('Error clearing expired cache: $e');
    }
  }

  /// Get cache timestamp for dashboard
  Future<DateTime?> getDashboardCacheTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_dashboardTimestampKey);
      if (timestampStr == null) return null;
      return DateTime.parse(timestampStr);
    } catch (e) {
      return null;
    }
  }

  /// Check if dashboard cache exists (regardless of freshness)
  Future<bool> hasDashboardCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_dashboardDataKey);
    } catch (e) {
      return false;
    }
  }

  /// Get stale dashboard data (even if expired)
  /// Useful for offline mode to show something rather than nothing
  Future<Map<String, dynamic>?> getStaleDashboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataStr = prefs.getString(_dashboardDataKey);
      if (dataStr == null) return null;
      return json.decode(dataStr) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting stale dashboard: $e');
      return null;
    }
  }
}
