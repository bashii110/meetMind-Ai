import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/priority_indicator.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/task_details_controller.dart';

const _statusOptions = ['pending', 'in_progress', 'completed', 'cancelled'];

class TaskDetailsScreen extends ConsumerStatefulWidget {
  const TaskDetailsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  final _commentController = TextEditingController();

  bool _sendingComment = false;
  bool _uploadingAttachment = false;
  // Tracked locally so the slider tracks the finger during a drag instead
  // of snapping back until updateProgress's request round-trips.
  int? _draggingProgress;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  TaskDetailsController _notifier() =>
      ref.read(taskDetailsControllerProvider(widget.taskId).notifier);

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _notifier().delete();
      if (context.mounted) context.pop();
    }
  }

  void _showError(Object e) {
    if (!mounted) return;
    final failure = e is ApiFailure ? e : ApiFailure.unknown(e.toString());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _sendingComment = true);
    try {
      await _notifier().addComment(text);
      _commentController.clear();
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _pickAttachment() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _uploadingAttachment = true);
    try {
      await _notifier().addAttachment(File(path));
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) setState(() => _uploadingAttachment = false);
    }
  }

  Future<void> _assignToMe() async {
    final me = ref.read(authControllerProvider).valueOrNull;
    if (me == null) return;
    try {
      await _notifier().assign(me.id);
    } catch (e) {
      _showError(e);
    }
  }

  Future<void> _unassign() async {
    try {
      await _notifier().assign(null);
    } catch (e) {
      _showError(e);
    }
  }

  String _formatSize(int? bytes) {
    if (bytes == null) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final task = ref.watch(taskDetailsControllerProvider(widget.taskId));
    final currentUserId = ref.watch(authControllerProvider).valueOrNull?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.taskEditPath(widget.taskId)),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _confirmDelete(context)),
        ],
      ),
      body: task.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(error is ApiFailure ? error.message : 'Could not load this task.'),
        ),
        data: (t) => ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Text(t.title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                StatusChip(status: t.status),
                const SizedBox(width: Spacing.md),
                PriorityIndicator(priority: t.priority),
                if (t.isOverdue) ...[
                  const SizedBox(width: Spacing.md),
                  Icon(Icons.warning_amber_rounded, size: 18, color: Theme.of(context).colorScheme.error),
                  const SizedBox(width: 4),
                  Text('Overdue', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Text('Status', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: Spacing.sm),
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final status in _statusOptions)
                  ChoiceChip(
                    label: Text(status.replaceAll('_', ' ')),
                    selected: t.status == status,
                    onSelected: (selected) => selected ? _notifier().changeStatus(status) : null,
                  ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            Text('Progress · ${_draggingProgress ?? t.progress}%', style: Theme.of(context).textTheme.labelMedium),
            Slider(
              value: (_draggingProgress ?? t.progress).toDouble(),
              min: 0,
              max: 100,
              divisions: 20,
              label: '${_draggingProgress ?? t.progress}%',
              onChanged: (value) => setState(() => _draggingProgress = value.round()),
              onChangeEnd: (value) async {
                await _notifier().updateProgress(value.round());
                if (mounted) setState(() => _draggingProgress = null);
              },
            ),
            const SizedBox(height: Spacing.md),
            Text('Assignee', style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  child: Text(
                    t.assignee != null && t.assignee!.name.isNotEmpty ? t.assignee!.name[0].toUpperCase() : '?',
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(child: Text(t.assignee?.name ?? 'Unassigned')),
                TextButton(onPressed: _assignToMe, child: const Text('Assign to me')),
                if (t.assignee != null) TextButton(onPressed: _unassign, child: const Text('Unassign')),
              ],
            ),
            if (t.deadline != null) ...[
              const SizedBox(height: Spacing.lg),
              _InfoRow(icon: Icons.event_outlined, label: DateFormat.yMMMEd().add_jm().format(t.deadline!)),
            ],
            if (t.meetingId != null) ...[
              const SizedBox(height: Spacing.sm),
              _InfoRow(
                icon: Icons.event_note_outlined,
                label: t.meetingTitle ?? 'Linked meeting',
                trailing: TextButton(
                  onPressed: () => context.push(AppRoutes.meetingDetailsPath(t.meetingId!)),
                  child: const Text('View'),
                ),
              ),
            ],
            if (t.description != null && t.description!.isNotEmpty) ...[
              const SizedBox(height: Spacing.lg),
              Text('Description', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: Spacing.xs),
              Text(t.description!),
            ],
            const SizedBox(height: Spacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
                TextButton.icon(
                  onPressed: _uploadingAttachment ? null : _pickAttachment,
                  icon: _uploadingAttachment
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.attach_file, size: 18),
                  label: const Text('Upload'),
                ),
              ],
            ),
            if (t.attachments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Text('No attachments yet.'),
              )
            else
              for (final attachment in t.attachments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(attachment.originalFilename),
                  subtitle: Text(_formatSize(attachment.size)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _notifier().deleteAttachment(attachment.id),
                  ),
                ),
            const SizedBox(height: Spacing.xl),
            Text('Comments', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.sm),
            if (t.comments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Text('No comments yet.'),
              )
            else
              for (final comment in t.comments)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 16,
                    child: Text(comment.user.name.isNotEmpty ? comment.user.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(comment.user.name),
                  subtitle: Text(comment.comment),
                  trailing: currentUserId == comment.user.id
                      ? IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18),
                          onPressed: () => _notifier().deleteComment(comment.id),
                        )
                      : null,
                ),
            const SizedBox(height: Spacing.sm),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(hintText: 'Add a comment'),
                    onSubmitted: (_) => _sendComment(),
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                _sendingComment
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(icon: const Icon(Icons.send), onPressed: _sendComment),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(label)),
        if (trailing != null) trailing!,
      ],
    );
  }
}
