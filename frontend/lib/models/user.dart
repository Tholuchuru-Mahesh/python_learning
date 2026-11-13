class User {
  final String id;
  final String username;
  final String fullName;
  final bool isOwner;
  final bool isActive;
  final List<String> permissions;

  User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.isOwner,
    this.isActive = true,
    required this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      isOwner: json['isOwner'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  bool hasPermission(String permission) {
    if (isOwner) return true;
    return permissions.contains(permission);
  }
}

