import 'package:equatable/equatable.dart';

/// SRD FR-16.1: "Admins shall manage (view/disable) user accounts."
/// Mirrors the shape `AppUser` maps (see
/// `auth/domain/entities/app_user.dart`) plus [isDisabled], which only
/// matters from the admin's point of view — a disabled user's own
/// session simply can't log in, so `AppUser` itself doesn't need it.
class AdminUser extends Equatable {
  const AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isDisabled,
    required this.createdAt,
    this.avatar,
  });

  final String id;
  final String name;
  final String email;

  /// regular_user | workspace_admin | system_admin — SRD 2.2.
  final String role;
  final bool isDisabled;
  final DateTime createdAt;
  final String? avatar;

  @override
  List<Object?> get props => [id, name, email, role, isDisabled, createdAt, avatar];
}

/// Matches the backend's `{ items, meta: {...} }` pagination envelope
/// used across every list endpoint in this app.
class PaginatedAdminUsers {
  const PaginatedAdminUsers({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<AdminUser> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
