import 'package:dio/dio.dart';

import '../../domain/entities/workspace_member.dart';
import '../models/department_model.dart';
import '../models/paginated_activity_model.dart';
import '../models/workspace_member_model.dart';
import '../models/workspace_model.dart';

/// Talks to /workspaces/* — see backend/routes/api.php and
/// ARCHITECTURE.md section 5's REST conventions. Returns typed models;
/// error mapping is handled by ErrorMappingInterceptor (core/network), so
/// callers here just propagate DioExceptions upward, same as every other
/// remote data source in this app.
class WorkspaceRemoteDataSource {
  const WorkspaceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<WorkspaceModel>> list() async {
    final response = await _dio.get('/workspaces');
    final list = response.data['data'] as List;
    return list.map((e) => WorkspaceModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WorkspaceModel> getById(String id) async {
    final response = await _dio.get('/workspaces/$id');
    return WorkspaceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<WorkspaceModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/workspaces', data: body);
    return WorkspaceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<WorkspaceModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put('/workspaces/$id', data: body);
    return WorkspaceModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/workspaces/$id');

  Future<void> leave(String id) => _dio.post('/workspaces/$id/leave');

  Future<List<WorkspaceMemberModel>> listMembers(String workspaceId) async {
    final response = await _dio.get('/workspaces/$workspaceId/members');
    final list = response.data['data'] as List;
    return list.map((e) => WorkspaceMemberModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// @return emails that didn't match a registered user.
  Future<List<String>> inviteMembers(String workspaceId, List<String> emails, WorkspaceRole role) async {
    final response = await _dio.post('/workspaces/$workspaceId/members', data: {
      'emails': emails,
      'role': role.apiValue,
    });
    final notFound = response.data['data']?['not_found_emails'] as List? ?? const [];
    return notFound.map((e) => e.toString()).toList();
  }

  Future<WorkspaceMemberModel> updateMemberRole(String workspaceId, String userId, WorkspaceRole role) async {
    final response = await _dio.patch('/workspaces/$workspaceId/members/$userId', data: {
      'role': role.apiValue,
    });
    return WorkspaceMemberModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> removeMember(String workspaceId, String userId) {
    return _dio.delete('/workspaces/$workspaceId/members/$userId');
  }

  Future<WorkspaceMemberModel> assignDepartment(String workspaceId, String userId, String? departmentId) async {
    final response = await _dio.patch('/workspaces/$workspaceId/members/$userId/department', data: {
      'department_id': departmentId != null ? (int.tryParse(departmentId) ?? departmentId) : null,
    });
    return WorkspaceMemberModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<DepartmentModel>> listDepartments(String workspaceId) async {
    final response = await _dio.get('/workspaces/$workspaceId/departments');
    final list = response.data['data'] as List;
    return list.map((e) => DepartmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DepartmentModel> createDepartment(String workspaceId, String name) async {
    final response = await _dio.post('/workspaces/$workspaceId/departments', data: {'name': name});
    return DepartmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<DepartmentModel> updateDepartment(String workspaceId, String departmentId, String name) async {
    final response = await _dio.put('/workspaces/$workspaceId/departments/$departmentId', data: {'name': name});
    return DepartmentModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDepartment(String workspaceId, String departmentId) {
    return _dio.delete('/workspaces/$workspaceId/departments/$departmentId');
  }

  Future<PaginatedActivityModel> listActivity(String workspaceId, int page) async {
    final response = await _dio.get(
      '/workspaces/$workspaceId/activity',
      queryParameters: {'page': page},
    );
    return PaginatedActivityModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
