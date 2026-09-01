import '../entities/department.dart';
import '../entities/paginated_activity.dart';
import '../entities/workspace.dart';
import '../entities/workspace_member.dart';

/// Implemented by data/repositories/workspace_repository_impl.dart. Use
/// cases and the presentation layer depend on this abstraction, never the
/// impl directly (ARCHITECTURE.md 2.1).
abstract interface class WorkspaceRepository {
  /// Every workspace the current user is a member of. Not paginated —
  /// same reasoning as `NotificationRepository.list`: a single user's
  /// workspace count is small enough that a flat list is simpler than a
  /// second pagination scheme for this one endpoint.
  Future<List<Workspace>> list();

  Future<Workspace> getById(String id);

  Future<Workspace> create({required String name, String? description});

  Future<Workspace> update(String id, {String? name, String? description});

  /// Only the owner may delete a workspace.
  Future<void> delete(String id);

  /// Removes the current user's own membership. Not available to the
  /// owner (who must delete the workspace instead).
  Future<void> leave(String id);

  Future<List<WorkspaceMember>> listMembers(String workspaceId);

  /// @return emails that didn't match a registered user — mirrors
  /// `MeetingRepository.inviteParticipants`'s contract.
  Future<List<String>> inviteMembers(
    String workspaceId,
    List<String> emails, {
    WorkspaceRole role = WorkspaceRole.member,
  });

  Future<WorkspaceMember> updateMemberRole(String workspaceId, String userId, WorkspaceRole role);

  Future<void> removeMember(String workspaceId, String userId);

  /// Pass `null` to unassign from any department.
  Future<WorkspaceMember> assignMemberDepartment(String workspaceId, String userId, String? departmentId);

  Future<List<Department>> listDepartments(String workspaceId);

  Future<Department> createDepartment(String workspaceId, String name);

  Future<Department> updateDepartment(String workspaceId, String departmentId, String name);

  Future<void> deleteDepartment(String workspaceId, String departmentId);

  Future<PaginatedActivity> listActivity(String workspaceId, {int page = 1});
}
