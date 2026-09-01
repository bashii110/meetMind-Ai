import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';

import '../../domain/entities/workspace.dart';
import 'workspace_providers.dart';

/// Every workspace the current user belongs to — PHASES.md Phase 7.
/// Deliberately NOT autoDispose (mirrors `MeetingsListController`): cheap
/// to keep cached across the app's lifetime, and rebuilding on every
/// screen visit would be wasteful for data that changes rarely.
class WorkspacesListController extends AsyncNotifier<List<Workspace>> {
  @override
  Future<List<Workspace>> build() {
    // Rebuild on login/logout/account switch — see MeetingsListController
    // for why this dependency matters.
    ref.watch(authControllerProvider.select((s) => s.valueOrNull?.id));
    return ref.read(listWorkspacesUseCaseProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(listWorkspacesUseCaseProvider)());
  }
}

final workspacesListControllerProvider =
    AsyncNotifierProvider<WorkspacesListController, List<Workspace>>(WorkspacesListController.new);
