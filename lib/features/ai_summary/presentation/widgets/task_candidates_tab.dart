import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai%20status/presentation/providers/ai_status_controller.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';
import 'package:meetmind_ai/features/tasks/presentation/providers/task_candidates_controller.dart';

import '../../../../../../core/network/api_failure.dart';
import '../../../../../../core/theme/spacing.dart';
import '../../../../../../core/utils/error_feedback.dart';
import '../../../../../../core/widgets/empty_state.dart';
import '../../../../../../core/widgets/priority_indicator.dart';
import '../../../ai status/presentation/screens/ai_status_states.dart';

class TaskCandidatesTab extends ConsumerWidget {
  const TaskCandidatesTab({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusControllerProvider(meetingId));

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (aiStatus) {
        if (!aiStatus.hasRecording) {
          return const AiEmptyState(
            icon: Icons.checklist_rounded,
            title: 'No suggested tasks yet',
            message: 'Record this meeting and MeetMind will suggest action items automatically.',
          );
        }
        if (aiStatus.hasFailed) {
          return AiFailedState(message: aiStatus.errorMessage ?? 'Processing failed.');
        }
        // Task candidates only exist once status reaches summarized —
        // ExtractTasksJob writes them before that (and runs after
        // GenerateSummaryJob), so this is also true for the summary.
        if (aiStatus.status != AiPipelineStatus.summarized) {
          return AiProcessingState(label: aiStatus.label);
        }

        final candidates = ref.watch(taskCandidatesControllerProvider(meetingId));
        return candidates.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
          data: (list) {
            final pending = list.where((c) => c.status == TaskCandidateStatus.pending).toList();
            if (pending.isEmpty) {
              return const EmptyState(
                icon: Icons.task_alt,
                title: 'No pending suggestions',
                message: "You've reviewed every AI-suggested task for this meeting.",
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(Spacing.lg),
              itemCount: pending.length,
              separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, index) =>
                  _TaskCandidateCard(meetingId: meetingId, candidate: pending[index]),
            );
          },
        );
      },
    );
  }
}

class _TaskCandidateCard extends ConsumerWidget {
  const _TaskCandidateCard({required this.meetingId, required this.candidate});

  final String meetingId;
  final TaskCandidate candidate;

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<_ConfirmResult>(
      context: context,
      builder: (context) => _ConfirmTaskDialog(candidate: candidate),
    );
    if (result == null || !context.mounted) return;

    await runOrNotify(context, () async {
      await ref.read(taskCandidatesControllerProvider(meetingId).notifier).confirm(
            candidate.id,
            title: result.title,
            priority: result.priority,
            deadline: result.deadline,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added "${result.title}" to tasks.')),
        );
      }
    });
  }

  Future<void> _dismiss(BuildContext context, WidgetRef ref) async {
    await runOrNotify(
      context,
      () => ref.read(taskCandidatesControllerProvider(meetingId).notifier).dismiss(candidate.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 16, color: scheme.tertiary),
                const SizedBox(width: Spacing.xs),
                Text(
                  'AI-suggested',
                  style: TextStyle(color: scheme.tertiary, fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                PriorityIndicator(priority: candidate.suggestedPriority),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(candidate.title, style: Theme.of(context).textTheme.titleMedium),
            if (candidate.description != null && candidate.description!.isNotEmpty) ...[
              const SizedBox(height: Spacing.xs),
              Text(candidate.description!),
            ],
            if (candidate.suggestedAssigneeName != null || candidate.suggestedDeadline != null) ...[
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.md,
                runSpacing: Spacing.xs,
                children: [
                  if (candidate.suggestedAssigneeName != null)
                    _MetaChip(icon: Icons.person_outline, label: candidate.suggestedAssigneeName!),
                  if (candidate.suggestedDeadline != null)
                    _MetaChip(
                      icon: Icons.event_outlined,
                      label: DateFormat.yMMMd().format(candidate.suggestedDeadline!),
                    ),
                ],
              ),
            ],
            const SizedBox(height: Spacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => _dismiss(context, ref), child: const Text('Dismiss')),
                const SizedBox(width: Spacing.sm),
                FilledButton(onPressed: () => _confirm(context, ref), child: const Text('Confirm')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _ConfirmResult {
  const _ConfirmResult({required this.title, required this.priority, this.deadline});

  final String title;
  final String priority;
  final DateTime? deadline;
}

/// FR-6.3: "Users shall review and confirm/edit AI-extracted tasks before
/// they are created" — this dialog is that review/edit step.
class _ConfirmTaskDialog extends StatefulWidget {
  const _ConfirmTaskDialog({required this.candidate});

  final TaskCandidate candidate;

  @override
  State<_ConfirmTaskDialog> createState() => _ConfirmTaskDialogState();
}

class _ConfirmTaskDialogState extends State<_ConfirmTaskDialog> {
  late final _title = TextEditingController(text: widget.candidate.title);
  late String _priority = widget.candidate.suggestedPriority;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _deadline = widget.candidate.suggestedDeadline;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirm task'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: Spacing.md),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (value) => setState(() => _priority = value ?? _priority),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: _pickDeadline,
              icon: const Icon(Icons.event_outlined, size: 18),
              label: Text(_deadline == null ? 'Set deadline' : DateFormat.yMMMd().format(_deadline!)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _ConfirmResult(title: _title.text.trim(), priority: _priority, deadline: _deadline),
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
