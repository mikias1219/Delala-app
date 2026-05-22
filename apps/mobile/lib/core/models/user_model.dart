class UserModel {
  const UserModel({
    required this.id,
    required this.phone,
    required this.role,
    this.fullName,
    required this.status,
    this.trustScore,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'renter',
      fullName: json['fullName'] as String?,
      status: json['status'] as String? ?? 'active',
      trustScore: json['trustScore'] is Map<String, dynamic>
          ? json['trustScore'] as Map<String, dynamic>
          : null,
    );
  }

  final String id;
  final String phone;
  final String role;
  final String? fullName;
  final String status;
  final Map<String, dynamic>? trustScore;
}
