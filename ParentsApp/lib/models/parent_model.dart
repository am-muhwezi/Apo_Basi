class Parent {
  final int userId;
  final String contactNumber;
  final String? address;
  final String? emergencyContact;
  final String status;

  Parent({
    required this.userId,
    required this.contactNumber,
    this.address,
    this.emergencyContact,
    required this.status,
  });

  factory Parent.fromJson(Map<String, dynamic> json) {
    return Parent(
      userId: json['user'],
      contactNumber: json['contact_number'] ?? '',
      address: json['address'],
      emergencyContact: json['emergency_contact'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': userId,
      'contact_number': contactNumber,
      'address': address,
      'emergency_contact': emergencyContact,
      'status': status,
    };
  }
}

class User {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
  });

  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      firstName: json['first_name'],
      lastName: json['last_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
    };
  }
}
