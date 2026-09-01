import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workspace_member.dart';
import 'workspace_providers.dart';

class WorkspaceMembersController extends AutoDisposeFamilyAsyncNotifier<List<WorkspaceMember>, String> {
  @override
  Future<List<WorkspaceMember>> build(String arg) => ref.read(listWorkspaceMembersUseCaseProvider)(arg);

  /// @return emails that didn't match a registered user (SRD FR-10.1).
  Future<List<String>> invite(List<String> emails, WorkspaceRole role) async {
    final notFound = await ref.read(inviteWorkspaceMembersUseCaseProvider)(arg, emails, role: role);
    await _reload();
    return notFound;
  }

  Future<void> updateRole(String userId, WorkspaceRole role) async {
    await ref.read(updateMemberRoleUseCaseProvider)(arg, userId, role);
    await _reload();
  }

  Future<void> remove(String userId) async {
    await ref.read(removeWorkspaceMemberUseCaseProvider)(arg, userId);
    await _reload();
  }

  Future<void> assignDepartment(String userId, String? departmentId) async {
    await ref.read(assignMemberDepartmentUseCaseProvider)(arg, userId, departmentId);
    await _reload();
  }

  /// Public alias for pull-to-refresh — see DepartmentsController.refresh
  /// for the same convention.
  Future<void> refresh() => _reload();

  Future<void> _reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(listWorkspaceMembersUseCaseProvider)(arg));
  }
}

final workspaceMembersControllerProvider = AsyncNotifierProvider.autoDispose
    .family<WorkspaceMembersController, List<WorkspaceMember>, String>(WorkspaceMembersController.new);
