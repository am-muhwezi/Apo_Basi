class AppConstants {
  // App Information
  static const String appName = 'Apo Basi';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'https://api.apobasi.com';
  static const String wsUrl = 'wss://api.apobasi.com/ws';
  static const Duration apiTimeout = Duration(seconds: 30);
  
  // Location Configuration
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const double distanceFilter = 10.0; // meters
  static const double busProximityThreshold = 100.0; // meters for notifications
  
  // Map Configuration
  static const double defaultZoom = 15.0;
  static const double busTrackingZoom = 17.0;
  static const int maxMapZoom = 20;
  static const int minMapZoom = 10;
  
  // Notification Configuration
  static const String notificationChannelId = 'bus_tracking_notifications';
  static const String notificationChannelName = 'Bus Tracking';
  static const String notificationChannelDescription = 'Notifications for bus arrival and departure';
  
  // Cache Configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // MB
  
  // User Roles
  static const String roleParent = 'parent';
  static const String roleDriver = 'driver';
  static const String roleAdmin = 'admin';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Please check your network.';
  static const String locationError = 'Unable to get location. Please enable location services.';
  static const String authError = 'Authentication failed. Please login again.';
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxPhoneLength = 15;
  
  // Storage Keys
  static const String keyUserToken = 'user_token';
  static const String keyUserRole = 'user_role';
  static const String keyUserProfile = 'user_profile';
  static const String keyNotificationSettings = 'notification_settings';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';
}