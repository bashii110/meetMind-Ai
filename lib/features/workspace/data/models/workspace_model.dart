import '../../domain/entities/workspace.dart';

class WorkspaceModel extends Workspace {
  const WorkspaceModel({
    required super.id,
    required super.name,
    required super.ownerId,
    required super.ownerName,
    required super.myRole,
    required super.createdAt,
    super.description,
    super.memberCount,
    super.departmentCount,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'] as Map<String, dynamic>?;

    return WorkspaceModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerId: (owner?['id'] ?? json['owner_id'] ?? '').toString(),
      ownerName: owner?['name'] as String? ?? '',
      myRole: json['my_role'] as String? ?? 'member',
      memberCount: json['member_count'] as int? ?? 0,
      departmentCount: json['department_count'] as int? ?? 0,
      createdAt: DateTime.tryParse(
        json['created_at']?.toString() ?? '',
      ) ?? DateTime.now(),
    );
  }
}
