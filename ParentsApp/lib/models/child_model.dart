class Child {
  final int id;
  final String firstName;
  final String lastName;
  final String classGrade;
  final Bus? assignedBus;
  final String? currentStatus;
  final DateTime? lastUpdated;

  Child({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.classGrade,
    this.assignedBus,
    this.currentStatus,
    this.lastUpdated,
  });

  String get fullName => '$firstName $lastName';

  factory Child.fromJson(Map<String, dynamic> json) {
    return Child(
      id: json['id'],
      // Handle both snake_case and camelCase from backend
      firstName: json['first_name'] ?? json['firstName'] ?? '',
      lastName: json['last_name'] ?? json['lastName'] ?? '',
      classGrade: json['class_grade'] ?? json['grade'] ?? '',
      assignedBus: json['assigned_bus'] != null
          ? Bus.fromJson(json['assigned_bus'])
          : (json['assignedBusId'] != null && json['assignedBusNumber'] != null)
              ? Bus(id: json['assignedBusId'], numberPlate: json['assignedBusNumber'])
              : null,
      currentStatus: json['current_status'],
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'class_grade': classGrade,
      'assigned_bus': assignedBus?.toJson(),
      'current_status': currentStatus,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

class Bus {
  final int id;
  final String numberPlate;

  Bus({
    required this.id,
    required this.numberPlate,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'],
      numberPlate: json['number_plate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number_plate': numberPlate,
    };
  }
}
