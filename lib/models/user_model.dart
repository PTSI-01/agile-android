class UserModel {
  final dynamic id;
  final String name;
  final String email;
  final String? role;
  final bool accountEnabled;
  final bool passwordSetupRequired;
  final Map<String, bool> permissions;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.accountEnabled = true,
    this.passwordSetupRequired = false,
    this.permissions = const {},
  });

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] as String? ?? 'User',
      email: json['email'] as String? ?? '',
      role: json['role'] as String?,
      accountEnabled: json['account_enabled'] is bool
          ? json['account_enabled'] as bool
          : (json['account_enabled'] == 1 || json['account_enabled'] == '1'),
      passwordSetupRequired: json['password_setup_required'] is bool
          ? json['password_setup_required'] as bool
          : (json['password_setup_required'] == 1 ||
              json['password_setup_required'] == '1'),
      permissions: (json['permissions'] as Map? ?? {}).map(
        (key, value) => MapEntry(key.toString(), value == true || value == 1),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'account_enabled': accountEnabled,
      'password_setup_required': passwordSetupRequired,
      'permissions': permissions,
    };
  }
}
