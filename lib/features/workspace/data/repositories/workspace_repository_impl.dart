import '../../domain/entities/department.dart';
import '../../domain/entities/paginated_activity.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_member.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_remote_data_source.dart';

class WorkspaceRepositoryImpl implements WorkspaceRepository {
  const WorkspaceRepositoryImpl(this._remote);

  final WorkspaceRemoteDataSource _remote;

  @override
  Future<List<Workspace>> list() => _remote.list();

  @override
  Future<Workspace> getById(String id) => _remote.getById(id);

  @override
  Future<Workspace> create({required String name, String? description}) {
    return _remote.create({
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  @override
  Future<Workspace> update(String id, {String? name, String? description}) {
    return _remote.update(id, {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
  }

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<void> leave(String id) => _remote.leave(id);

  @override
  Future<List<WorkspaceMember>> listMembers(String workspaceId) => _remote.listMembers(workspaceId);

  @override
  Future<List<String>> inviteMembers(
    String workspaceId,
    List<String> emails, {
    WorkspaceRole role = WorkspaceRole.member,
  }) {
    return _remote.inviteMembers(workspaceId, emails, role);
  }

  @override
  Future<WorkspaceMember> updateMemberRole(String workspaceId, String userId, WorkspaceRole role) {
    return _remote.updateMemberRole(workspaceId, userId, role);
  }

  @override
  Future<void> removeMember(String workspaceId, String userId) => _remote.removeMember(workspaceId, userId);

  @override
  Future<WorkspaceMember> assignMemberDepartment(String workspaceId, String userId, String? departmentId) {
    return _remote.assignDepartment(workspaceId, userId, departmentId);
  }

  @override
  Future<List<Department>> listDepartments(String workspaceId) => _remote.listDepartments(workspaceId);

  @override
  Future<Department> createDepartment(String workspaceId, String name) {
    return _remote.createDepartment(workspaceId, name);
  }

  @override
  Future<Department> updateDepartment(String workspaceId, String departmentId, String name) {
    return _remote.updateDepartment(workspaceId, departmentId, name);
  }

  @override
  Future<void> deleteDepartment(String workspaceId, String departmentId) {
    return _remote.deleteDepartment(workspaceId, departmentId);
  }

  @override
  Future<PaginatedActivity> listActivity(String workspaceId, {int page = 1}) {
    return _remote.listActivity(workspaceId, page);
  }
}
