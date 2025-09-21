import 'package:equatable/equatable.dart';

class Student extends Equatable {
  final String id;
  final String firstName;
  final String lastName;
  final String schoolId;
  final String routeId;
  final String? busStopId;
  final List<String> parentIds;
  final DateTime dateOfBirth;
  final String grade;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.schoolId,
    required this.routeId,
    this.busStopId,
    required this.parentIds,
    required this.dateOfBirth,
    required this.grade,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName';

  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        schoolId,
        routeId,
        busStopId,
        parentIds,
        dateOfBirth,
        grade,
        profileImageUrl,
        createdAt,
        updatedAt,
      ];
}