import '../entities/workspace_member.dart';
import '../repositories/workspace_repository.dart';

class ListWorkspaceMembersUseCase {
  const ListWorkspaceMembersUseCase(this._repository);

  final WorkspaceRepository _repository;

  Future<List<WorkspaceMember>> call(String workspaceId) => _repository.listMembers(workspaceId);
}
