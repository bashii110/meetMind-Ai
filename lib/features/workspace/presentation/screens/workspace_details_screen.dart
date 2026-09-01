import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/utils/error_feedback.dart';
import '../../../../core/widgets/chip_input_field.dart';
import '../../domain/entities/department.dart';
import '../../domain/entities/workspace.dart';
import '../../domain/entities/workspace_member.dart';
import '../providers/departments_controller.dart';
import '../providers/workspace_activity_controller.dart';
import '../providers/workspace_details_controller.dart';
import '../providers/workspace_members_controller.dart';
import '../widgets/activity_log_tile.dart';
import '../widgets/department_tile.dart';
import '../widgets/member_tile.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// SRD FR-10.1–10.4: workspace overview, member/role management, optional
/// department grouping, and the activity timeline, each as its own tab —
/// mirrors `MeetingDetailsScreen`'s tabbed layout.
class WorkspaceDetailsScreen extends ConsumerStatefulWidget {
  const WorkspaceDetailsScreen({super.key, required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<WorkspaceDetailsScreen> createState() => _WorkspaceDetailsScreenState();
}

class _WorkspaceDetailsScreenState extends ConsumerState<WorkspaceDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteOrLeave(BuildContext context, bool isOwner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isOwner ? 'Delete workspace?' : 'Leave workspace?'),
        content: Text(
          isOwner
              ? 'This removes the workspace and all its members. This cannot be undone.'
              : "You'll lose access to this workspace's meetings and tasks.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(isOwner ? 'Delete' : 'Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(workspaceDetailsControllerProvider(widget.workspaceId).notifier);
    await runOrNotify(context, () async {
      if (isOwner) {
        await notifier.delete();
      } else {
        await notifier.leave();
      }
      if (context.mounted) context.pop();
    });
  }

  Future<void> _inviteDialog(BuildContext context) async {
    var emails = <String>[];
    var role = WorkspaceRole.member;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite members'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChipInputField(
                  label: 'Email',
                  values: emails,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => _emailPattern.hasMatch(v) ? null : 'Enter a valid email',
                  onChanged: (values) => setState(() => emails = values),
                ),
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<WorkspaceRole>(
                  initialValue: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: WorkspaceRole.member, child: Text('Member')),
                    DropdownMenuItem(value: WorkspaceRole.admin, child: Text('Admin')),
                  ],
                  onChanged: (value) => setState(() => role = value ?? role),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: emails.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await runOrNotify(context, () async {
                        final notFound = await ref
                            .read(workspaceMembersControllerProvider(widget.workspaceId).notifier)
                            .invite(emails, role);
                        if (notFound.isNotEmpty && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No account found for: ${notFound.join(', ')}')),
                          );
                        }
                      });
                    },
              child: const Text('Send invites'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeRoleDialog(BuildContext context, WorkspaceMember member) async {
    var role = member.role;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Change role · ${member.name}'),
          content: DropdownButtonFormField<WorkspaceRole>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'Role'),
            items: const [
              DropdownMenuItem(value: WorkspaceRole.member, child: Text('Member')),
              DropdownMenuItem(value: WorkspaceRole.admin, child: Text('Admin')),
            ],
            onChanged: (value) => setState(() => role = value ?? role),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(workspaceMembersControllerProvider(widget.workspaceId).notifier).updateRole(
            member.userId,
            role,
          ),
    );
  }

  Future<void> _assignDepartmentDialog(
    BuildContext context,
    WorkspaceMember member,
    List<Department> departments,
  ) async {
    String? departmentId = member.departmentId;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign department · ${member.name}'),
          content: DropdownButtonFormField<String?>(
            initialValue: departmentId,
            decoration: const InputDecoration(labelText: 'Department'),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('None')),
              for (final d in departments) DropdownMenuItem<String?>(value: d.id, child: Text(d.name)),
            ],
            onChanged: (value) => setState(() => departmentId = value),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref
          .read(workspaceMembersControllerProvider(widget.workspaceId).notifier)
          .assignDepartment(member.userId, departmentId),
    );
  }

  Future<void> _confirmRemoveMember(BuildContext context, WorkspaceMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text('${member.name} will lose access to this workspace.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(workspaceMembersControllerProvider(widget.workspaceId).notifier).remove(member.userId),
    );
  }

  Future<void> _addDepartmentDialog(BuildContext context) async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New department'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Department name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(departmentsControllerProvider(widget.workspaceId).notifier).create(name),
    );
  }

  Future<void> _renameDepartmentDialog(BuildContext context, Department department) async {
    final controller = TextEditingController(text: department.name);

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename department'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(departmentsControllerProvider(widget.workspaceId).notifier).updateProfile(department.id, name),
    );
  }

  Future<void> _confirmDeleteDepartment(BuildContext context, Department department) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete department?'),
        content: Text('"${department.name}" will be removed. Members keep their workspace access.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await runOrNotify(
      context,
      () => ref.read(departmentsControllerProvider(widget.workspaceId).notifier).delete(department.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workspace = ref.watch(workspaceDetailsControllerProvider(widget.workspaceId));

    return Scaffold(
      body: workspace.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
        data: (w) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(w.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              pinned: true,
              actions: [
                if (w.canManage)
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push(AppRoutes.workspaceEditPath(w.id)),
                  ),
                IconButton(
                  icon: Icon(w.isOwner ? Icons.delete_outline : Icons.logout),
                  onPressed: () => _confirmDeleteOrLeave(context, w.isOwner),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Departments'),
                  Tab(text: 'Activity'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(workspace: w),
              _MembersTab(
                workspaceId: w.id,
                canManage: w.canManage,
                onInvite: () => _inviteDialog(context),
                onChangeRole: (m) => _changeRoleDialog(context, m),
                onAssignDepartment: (m, depts) => _assignDepartmentDialog(context, m, depts),
                onRemove: (m) => _confirmRemoveMember(context, m),
              ),
              _DepartmentsTab(
                workspaceId: w.id,
                canManage: w.canManage,
                onAdd: () => _addDepartmentDialog(context),
                onEdit: (d) => _renameDepartmentDialog(context, d),
                onDelete: (d) => _confirmDeleteDepartment(context, d),
              ),
              _ActivityTab(workspaceId: w.id),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.workspace});

  final Workspace workspace;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        if (workspace.description != null && workspace.description!.isNotEmpty) ...[
          Text('Description', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Spacing.xs),
          Text(workspace.description!),
          const SizedBox(height: Spacing.lg),
        ],
        _InfoRow(icon: Icons.person_outline, label: 'Owned by ${workspace.ownerName}'),
        const SizedBox(height: Spacing.sm),
        _InfoRow(icon: Icons.event_outlined, label: 'Created ${DateFormat.yMMMd().format(workspace.createdAt)}'),
        const SizedBox(height: Spacing.sm),
        _InfoRow(
          icon: Icons.corporate_fare,
          label: '${workspace.departmentCount} department${workspace.departmentCount == 1 ? '' : 's'}',
        ),
        const SizedBox(height: Spacing.lg),
        Text('Your role', style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          workspace.myRole.isEmpty
              ? workspace.myRole
              : workspace.myRole[0].toUpperCase() + workspace.myRole.substring(1),
          style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(label)),
      ],
    );
  }
}

class _MembersTab extends ConsumerWidget {
  const _MembersTab({
    required this.workspaceId,
    required this.canManage,
    required this.onInvite,
    required this.onChangeRole,
    required this.onAssignDepartment,
    required this.onRemove,
  });

  final String workspaceId;
  final bool canManage;
  final VoidCallback onInvite;
  final void Function(WorkspaceMember member) onChangeRole;
  final void Function(WorkspaceMember member, List<Department> departments) onAssignDepartment;
  final void Function(WorkspaceMember member) onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = ref.watch(workspaceMembersControllerProvider(workspaceId));
    // Watched here too so the "assign department" dialog has the current
    // department list without the Members tab depending on the
    // Departments tab having been opened first.
    final departments = ref.watch(departmentsControllerProvider(workspaceId)).valueOrNull ?? const [];

    return members.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.read(workspaceMembersControllerProvider(workspaceId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
          children: [
            if (canManage)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onInvite,
                    icon: const Icon(Icons.person_add_alt, size: 18),
                    label: const Text('Invite members'),
                  ),
                ),
              ),
            for (final member in list) ...[
              MemberTile(
                member: member,
                canManage: canManage,
                onChangeRole: () => onChangeRole(member),
                onAssignDepartment: () => onAssignDepartment(member, departments),
                onRemove: () => onRemove(member),
              ),
              const Divider(height: 1),
            ],
          ],
        ),
      ),
    );
  }
}

class _DepartmentsTab extends ConsumerWidget {
  const _DepartmentsTab({
    required this.workspaceId,
    required this.canManage,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final String workspaceId;
  final bool canManage;
  final VoidCallback onAdd;
  final void Function(Department department) onEdit;
  final void Function(Department department) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentsControllerProvider(workspaceId));

    return departments.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (list) => RefreshIndicator(
        onRefresh: () => ref.read(departmentsControllerProvider(workspaceId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
          children: [
            if (canManage)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add department'),
                  ),
                ),
              ),
            if (list.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
                child: Text(
                  'No departments yet.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              )
            else
              for (final department in list) ...[
                DepartmentTile(
                  department: department,
                  canManage: canManage,
                  onEdit: () => onEdit(department),
                  onDelete: () => onDelete(department),
                ),
                const Divider(height: 1),
              ],
          ],
        ),
      ),
    );
  }
}

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity = ref.watch(workspaceActivityControllerProvider(workspaceId));

    return activity.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (state) {
        if (state.items.isEmpty) {
          return Center(
            child: Text(
              'No activity yet.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(workspaceActivityControllerProvider(workspaceId).notifier).refresh(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.lg),
            itemCount: state.items.length + (state.hasMore ? 1 : 0),
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index >= state.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                  child: Center(
                    child: state.isLoadingMore
                        ? const CircularProgressIndicator()
                        : TextButton(
                            onPressed: () =>
                                ref.read(workspaceActivityControllerProvider(workspaceId).notifier).loadMore(),
                            child: const Text('Load more'),
                          ),
                  ),
                );
              }
              return ActivityLogTile(entry: state.items[index]);
            },
          ),
        );
      },
    );
  }
}
