class UserModel {
  final int id;
  final String phoneNumber;
  final String? name;
  final String? email;
  final String role;
  final bool isActive;

  UserModel({
    required this.id,
    required this.phoneNumber,
    this.name,
    this.email,
    required this.role,
    required this.isActive,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      phoneNumber: json['phoneNumber'] as String,
      name: json['name'] as String?,
      email: json['email'] as String?,
      role: json['role'] as String? ?? 'customer',
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}

