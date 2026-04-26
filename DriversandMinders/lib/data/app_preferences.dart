/// User-configurable app settings stored in memory and persisted as a JSON blob.
///
/// Defaults are applied on first launch. Changed via the settings screens using
/// [AppStore.instance.savePrefs(prefs.copyWith(...))].
class AppPreferences {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool locationTrackingEnabled;
  final String language;
  final String distanceUnit;

  const AppPreferences({
    required this.notificationsEnabled,
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.locationTrackingEnabled,
    required this.language,
    required this.distanceUnit,
  });

  factory AppPreferences.defaults() => const AppPreferences(
        notificationsEnabled: true,
        soundEnabled: true,
        vibrationEnabled: true,
        locationTrackingEnabled: true,
        language: 'en',
        distanceUnit: 'km',
      );

  factory AppPreferences.fromJson(Map<String, dynamic> j) => AppPreferences(
        notificationsEnabled: (j['notifications_enabled'] as bool?) ?? true,
        soundEnabled: (j['sound_enabled'] as bool?) ?? true,
        vibrationEnabled: (j['vibration_enabled'] as bool?) ?? true,
        locationTrackingEnabled:
            (j['location_tracking_enabled'] as bool?) ?? true,
        language: (j['language'] as String?) ?? 'en',
        distanceUnit: (j['distance_unit'] as String?) ?? 'km',
      );

  Map<String, dynamic> toJson() => {
        'notifications_enabled': notificationsEnabled,
        'sound_enabled': soundEnabled,
        'vibration_enabled': vibrationEnabled,
        'location_tracking_enabled': locationTrackingEnabled,
        'language': language,
        'distance_unit': distanceUnit,
      };

  AppPreferences copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? locationTrackingEnabled,
    String? language,
    String? distanceUnit,
  }) =>
      AppPreferences(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
        locationTrackingEnabled:
            locationTrackingEnabled ?? this.locationTrackingEnabled,
        language: language ?? this.language,
        distanceUnit: distanceUnit ?? this.distanceUnit,
      );
}
