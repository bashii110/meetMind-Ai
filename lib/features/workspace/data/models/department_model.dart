import '../../domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({
    required super.id,
    required super.workspaceId,
    required super.name,
    super.memberCount,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id'].toString(),
      workspaceId: json['workspace_id'].toString(),
      name: json['name'] as String? ?? '',
      memberCount: json['member_count'] as int? ?? 0,
    );
  }
}
