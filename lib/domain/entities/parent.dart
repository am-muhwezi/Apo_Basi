import 'package:equatable/equatable.dart';

class Parent extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final List<String> childrenIds;
  final NotificationSettings notificationSettings;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Parent({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.childrenIds,
    required this.notificationSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  @override
  List<Object> get props => [
        id,
        firstName,
        lastName,
        email,
        phoneNumber,
        childrenIds,
        notificationSettings,
        createdAt,
        updatedAt,
      ];
}

class NotificationSettings extends Equatable {
  final bool busArrivalNotifications;
  final bool busDepartureNotifications;
  final bool emergencyNotifications;
  final int notificationRadius; // in meters
  final List<String> notificationTimes; // e.g., ['07:30', '15:30']

  const NotificationSettings({
    required this.busArrivalNotifications,
    required this.busDepartureNotifications,
    required this.emergencyNotifications,
    required this.notificationRadius,
    required this.notificationTimes,
  });

  @override
  List<Object> get props => [
        busArrivalNotifications,
        busDepartureNotifications,
        emergencyNotifications,
        notificationRadius,
        notificationTimes,
      ];
}