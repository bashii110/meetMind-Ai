import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/workspaces_list_controller.dart';
import '../widgets/workspace_card.dart';

/// PHASES.md Phase 7 / SRD FR-10.1: "Users shall create/join workspaces."
class WorkspaceListScreen extends ConsumerWidget {
  const WorkspaceListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaces = ref.watch(workspacesListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workspaces')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.workspaceNew),
        icon: const Icon(Icons.add),
        label: const Text('New workspace'),
      ),
      body: workspaces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.workspaces_outlined,
              title: 'No workspaces yet',
              message: 'Create a workspace to start collaborating with your team.',
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(workspacesListControllerProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, index) {
                final workspace = list[index];
                return WorkspaceCard(
                  workspace: workspace,
                  onTap: () => context.push(AppRoutes.workspaceDetailsPath(workspace.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
