import 'package:equatable/equatable.dart';

/// ARCHITECTURE.md `workspace_members` table. Only owner/admin/member are
/// modeled here — System Admin (SRD 2.2) is a platform-wide role handled
/// by the separate `admin` feature, not a workspace membership role.
enum WorkspaceRole { owner, admin, member }

extension WorkspaceRoleX on WorkspaceRole {
  String get apiValue => name;

  String get label => switch (this) {
        WorkspaceRole.owner => 'Owner',
        WorkspaceRole.admin => 'Admin',
        WorkspaceRole.member => 'Member',
      };

  static WorkspaceRole fromApi(String? raw) {
    return WorkspaceRole.values.firstWhere(
      (r) => r.apiValue == raw,
      orElse: () => WorkspaceRole.member,
    );
  }
}

/// A user's membership in a workspace — SRD FR-10.1/10.2.
class WorkspaceMember extends Equatable {
  const WorkspaceMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.avatar,
    this.departmentId,
    this.departmentName,
  });

  final String userId;
  final String name;
  final String email;
  final String? avatar;
  final WorkspaceRole role;
  final String? departmentId;
  final String? departmentName;
  final DateTime joinedAt;

  @override
  List<Object?> get props =>
      [userId, name, email, avatar, role, departmentId, departmentName, joinedAt];
}
