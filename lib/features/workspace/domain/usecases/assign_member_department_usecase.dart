import '../entities/workspace_member.dart';
import '../repositories/workspace_repository.dart';

class AssignMemberDepartmentUseCase {
  const AssignMemberDepartmentUseCase(this._repository);

  final WorkspaceRepository _repository;

  /// Pass `null` for [departmentId] to unassign.
  Future<WorkspaceMember> call(String workspaceId, String userId, String? departmentId) {
    return _repository.assignMemberDepartment(workspaceId, userId, departmentId);
  }
}
