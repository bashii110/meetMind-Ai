import '../entities/workspace_member.dart';
import '../repositories/workspace_repository.dart';

class UpdateMemberRoleUseCase {
  const UpdateMemberRoleUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<WorkspaceMember> call(String workspaceId, String userId, WorkspaceRole role) {
    return _repository.updateMemberRole(workspaceId, userId, role);
  }
}
