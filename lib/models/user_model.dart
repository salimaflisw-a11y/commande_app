class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'client' or 'admin'
  final DateTime createdAt;

  UserModel({
    required this.id,
    this.name = '',
    required this.email,
    this.phone = '',
    required this.role,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final roleRaw = json['role']?.toString().trim();
    final roleVal = (roleRaw != null && roleRaw.isNotEmpty) ? roleRaw : 'client';

    DateTime createdAtDate = DateTime.now();
    final createdAtRaw = json['createdAt']?.toString();
    if (createdAtRaw != null && createdAtRaw.isNotEmpty) {
      final parsed = DateTime.tryParse(createdAtRaw);
      if (parsed != null) {
        createdAtDate = parsed;
      }
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: roleVal,
      createdAt: createdAtDate,
    );
  }
}
