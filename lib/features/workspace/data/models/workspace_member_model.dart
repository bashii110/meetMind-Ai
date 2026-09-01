import '../../domain/entities/workspace_member.dart';

class WorkspaceMemberModel extends WorkspaceMember {
  const WorkspaceMemberModel({
    required super.userId,
    required super.name,
    required super.email,
    required super.role,
    required super.joinedAt,
    super.avatar,
    super.departmentId,
    super.departmentName,
  });

  factory WorkspaceMemberModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    final department = json['department'] as Map<String, dynamic>?;

    return WorkspaceMemberModel(
      userId: (user?['id'] ?? json['user_id'] ?? '').toString(),
      name: user?['name'] as String? ?? '',
      email: user?['email'] as String? ?? '',
      avatar: user?['avatar'] as String?,
      role: WorkspaceRoleX.fromApi(json['role'] as String?),
      departmentId: department?['id']?.toString(),
      departmentName: department?['name'] as String?,
      joinedAt: DateTime.parse((json['joined_at'] ?? json['created_at']) as String),
    );
  }
}
