import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workspace.dart';
import 'workspace_providers.dart';
import 'workspaces_list_controller.dart';

class WorkspaceDetailsController extends AutoDisposeFamilyAsyncNotifier<Workspace, String> {
  @override
  Future<Workspace> build(String arg) => ref.read(getWorkspaceUseCaseProvider)(arg);

  Future<void> updateDetails({String? name, String? description}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(updateWorkspaceUseCaseProvider)(arg, name: name, description: description),
    );
    if (state.hasError) throw state.error!;
    _refreshList();
  }

  Future<void> delete() async {
    await ref.read(deleteWorkspaceUseCaseProvider)(arg);
    _refreshList();
  }

  Future<void> leave() async {
    await ref.read(leaveWorkspaceUseCaseProvider)(arg);
    _refreshList();
  }

  void _refreshList() {
    // Best-effort, same convention as MeetingDetailsController — the list
    // screen (if mounted) picks up the change next time it's visible.
    ref.read(workspacesListControllerProvider.notifier).refresh();
  }
}

final workspaceDetailsControllerProvider =
    AsyncNotifierProvider.autoDispose.family<WorkspaceDetailsController, Workspace, String>(
  WorkspaceDetailsController.new,
);
