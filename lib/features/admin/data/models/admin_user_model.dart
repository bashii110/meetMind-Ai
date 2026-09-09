import '../../domain/entities/admin_user.dart';

class AdminUserModel extends AdminUser {
  const AdminUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.role,
    required super.isDisabled,
    required super.createdAt,
    super.avatar,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'regular_user',
      isDisabled: json['is_disabled'] as bool? ?? false,
      avatar: json['avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class PaginatedAdminUsersModel extends PaginatedAdminUsers {
  const PaginatedAdminUsersModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  factory PaginatedAdminUsersModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return PaginatedAdminUsersModel(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
    );
  }
}
