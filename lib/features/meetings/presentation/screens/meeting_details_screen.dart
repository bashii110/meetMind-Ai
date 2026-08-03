import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/chip_input_field.dart';
import '../../../../core/widgets/priority_indicator.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/entities/meeting.dart';
import '../providers/meeting_details_controller.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class MeetingDetailsScreen extends ConsumerStatefulWidget {
  const MeetingDetailsScreen({super.key, required this.meetingId});

  final String meetingId;

  @override
  ConsumerState<MeetingDetailsScreen> createState() => _MeetingDetailsScreenState();
}

class _MeetingDetailsScreenState extends ConsumerState<MeetingDetailsScreen>
    with SingleTickerProviderStateMixin {
  late final _tabController = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete meeting?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(meetingDetailsControllerProvider(widget.meetingId).notifier).delete();
      if (context.mounted) context.pop();
    }
  }

  Future<void> _inviteDialog(BuildContext context) async {
    var emails = <String>[];
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Invite participants'),
          content: SizedBox(
            width: 320,
            child: ChipInputField(
              label: 'Email',
              values: emails,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => _emailPattern.hasMatch(v) ? null : 'Enter a valid email',
              onChanged: (values) => setState(() => emails = values),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: emails.isEmpty
                  ? null
                  : () async {
                      Navigator.pop(context);
                      final notFound = await ref
                          .read(meetingDetailsControllerProvider(widget.meetingId).notifier)
                          .inviteParticipants(emails);
                      if (notFound.isNotEmpty && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('No account found for: ${notFound.join(', ')}')),
                        );
                      }
                    },
              child: const Text('Send invites'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meeting = ref.watch(meetingDetailsControllerProvider(widget.meetingId));

    return Scaffold(
      body: meeting.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiFailure ? error.message : 'Could not load this meeting.'),
        ),
        data: (m) => NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              title: Text(m.title, maxLines: 1, overflow: TextOverflow.ellipsis),
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => context.push(AppRoutes.meetingEditPath(m.id)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Transcript'),
                  Tab(text: 'Summary'),
                  Tab(text: 'Tasks'),
                  Tab(text: 'Files'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(meeting: m, onInvite: () => _inviteDialog(context)),
              const _ComingSoonTab(label: 'Transcript', phase: 'Phase 4'),
              const _ComingSoonTab(label: 'AI Summary', phase: 'Phase 4'),
              const _ComingSoonTab(label: 'Tasks', phase: 'Phase 5'),
              const _ComingSoonTab(label: 'Files', phase: 'Phase 7'),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab({required this.meeting, required this.onInvite});

  final Meeting meeting;
  final VoidCallback onInvite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;
    final myParticipation = meeting.participants.where((p) => p.userId == currentUserId).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Row(
          children: [
            StatusChip(status: meeting.status),
            const SizedBox(width: Spacing.md),
            PriorityIndicator(priority: meeting.priority),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        if (meeting.status == 'draft' || meeting.status == 'scheduled')
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.lg),
            child: Wrap(
              spacing: Spacing.sm,
              children: [
                if (meeting.status == 'draft')
                  FilledButton(
                    onPressed: () => ref
                        .read(meetingDetailsControllerProvider(meeting.id).notifier)
                        .changeStatus('scheduled'),
                    child: const Text('Mark as scheduled'),
                  ),
                if (meeting.status == 'scheduled')
                  FilledButton(
                    onPressed: () => ref
                        .read(meetingDetailsControllerProvider(meeting.id).notifier)
                        .changeStatus('completed'),
                    child: const Text('Mark as completed'),
                  ),
                OutlinedButton(
                  onPressed: () =>
                      ref.read(meetingDetailsControllerProvider(meeting.id).notifier).changeStatus('cancelled'),
                  child: const Text('Cancel meeting'),
                ),
              ],
            ),
          ),
        if (myParticipation != null && myParticipation.inviteStatus == 'pending')
          Card(
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("You're invited to this meeting"),
                  const SizedBox(height: Spacing.sm),
                  Row(
                    children: [
                      FilledButton(
                        onPressed: () => ref
                            .read(meetingDetailsControllerProvider(meeting.id).notifier)
                            .respondToInvitation('accepted'),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: Spacing.sm),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(meetingDetailsControllerProvider(meeting.id).notifier)
                            .respondToInvitation('declined'),
                        child: const Text('Decline'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: Spacing.lg),
        _InfoRow(icon: Icons.calendar_today, label: DateFormat.yMMMEd().format(meeting.date)),
        if (meeting.time != null) _InfoRow(icon: Icons.access_time, label: meeting.time!),
        if (meeting.location != null && meeting.location!.isNotEmpty)
          _InfoRow(icon: Icons.location_on_outlined, label: meeting.location!),
        if (meeting.onlineLink != null && meeting.onlineLink!.isNotEmpty)
          _InfoRow(icon: Icons.link, label: meeting.onlineLink!),
        if (meeting.category != null && meeting.category!.isNotEmpty)
          _InfoRow(icon: Icons.category_outlined, label: meeting.category!),
        if (meeting.description != null && meeting.description!.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Text('Description', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: Spacing.xs),
          Text(meeting.description!),
        ],
        if (meeting.tags.isNotEmpty) ...[
          const SizedBox(height: Spacing.lg),
          Wrap(
            spacing: Spacing.sm,
            children: [for (final tag in meeting.tags) Chip(label: Text(tag))],
          ),
        ],
        const SizedBox(height: Spacing.xl),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Participants', style: Theme.of(context).textTheme.titleSmall),
            TextButton.icon(
              onPressed: onInvite,
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Invite'),
            ),
          ],
        ),
        if (meeting.ownerName != null) _ParticipantRow(name: meeting.ownerName!, status: 'Owner'),
        for (final p in meeting.participants) _ParticipantRow(name: p.name, status: p.inviteStatus),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: Spacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({required this.name, required this.status});

  final String name;
  final String status;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?')),
      title: Text(name),
      trailing: status == 'Owner' ? null : StatusChip(status: status),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({required this.label, required this.phase});

  final String label;
  final String phase;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '$label arrives in $phase',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}
