/// Typed representation of the authenticated user stored in memory.
///
/// Populated from the server response at login and restored from the
/// `user_session` JSON blob in SharedPreferences on app restart.
class UserSession {
  final int userId;
  final String name;
  final String email;
  final String phone;
  /// Either `'driver'` or `'busminder'`.
  final String role;
  final String licenseNumber;
  final String licenseExpiry;

  const UserSession({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.licenseNumber,
    required this.licenseExpiry,
  });

  static const UserSession _empty = UserSession(
    userId: 0,
    name: '',
    email: '',
    phone: '',
    role: 'driver',
    licenseNumber: '',
    licenseExpiry: '',
  );

  factory UserSession.empty() => _empty;

  bool get isLoggedIn => userId != 0;
  bool get isDriver => role == 'driver';
  bool get isBusMinder => role == 'busminder';

  factory UserSession.fromJson(Map<String, dynamic> j) => UserSession(
        userId: (j['user_id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        phone: (j['phone'] as String?) ?? '',
        role: (j['role'] as String?) ?? 'driver',
        licenseNumber: (j['license_number'] as String?) ?? '',
        licenseExpiry: (j['license_expiry'] as String?) ?? '',
      );

  /// Builds a [UserSession] from a raw Django auth API response.
  ///
  /// The server sends `user_type` for role; falls back to `'driver'`.
  factory UserSession.fromApiResponse(Map<String, dynamic> data) =>
      UserSession(
        userId: (data['user_id'] as num?)?.toInt() ?? 0,
        name: (data['name'] as String?) ?? '',
        email: (data['email'] as String?) ?? '',
        phone: (data['phone'] as String?) ?? '',
        role: (data['user_type'] as String?) ?? 'driver',
        licenseNumber: (data['license_number'] as String?) ?? '',
        licenseExpiry: (data['license_expiry'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'license_number': licenseNumber,
        'license_expiry': licenseExpiry,
      };

  UserSession copyWith({
    int? userId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? licenseNumber,
    String? licenseExpiry,
  }) =>
      UserSession(
        userId: userId ?? this.userId,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      );
}
