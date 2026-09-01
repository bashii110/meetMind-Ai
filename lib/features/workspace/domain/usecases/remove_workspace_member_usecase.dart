import '../repositories/workspace_repository.dart';

class RemoveWorkspaceMemberUseCase {
  const RemoveWorkspaceMemberUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<void> call(String workspaceId, String userId) => _repository.removeMember(workspaceId, userId);
}
