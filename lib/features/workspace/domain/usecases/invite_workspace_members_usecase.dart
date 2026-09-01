import '../entities/workspace_member.dart';
import '../repositories/workspace_repository.dart';

class InviteWorkspaceMembersUseCase {
  const InviteWorkspaceMembersUseCase(this._repository);

  final WorkspaceRepository _repository;

  /// @return emails that didn't match a registered user.
  Future<List<String>> call(
    String workspaceId,
    List<String> emails, {
    WorkspaceRole role = WorkspaceRole.member,
  }) {
    return _repository.inviteMembers(workspaceId, emails, role: role);
  }
}
