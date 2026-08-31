class AppUser {
  final String id;
  final String email;
  final String? fullName;
  final String role;

  AppUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String?,
      role: json['role'] as String,
    );
  }
}