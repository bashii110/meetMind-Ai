import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../meetings/presentation/providers/meetings_list_controller.dart';
import '../../domain/entities/task.dart';
import '../providers/task_details_controller.dart';
import '../providers/task_providers.dart';
import '../providers/tasks_list_controller.dart';

const _priorities = ['low', 'medium', 'high'];
// StoreTaskRequest only allows starting a new task as pending or
// in_progress — completed/cancelled are set later via the status endpoint.
const _createStatuses = ['pending', 'in_progress'];

/// Pass [taskId] to edit an existing task, or leave it null to create a new
/// one — SRD FR-7.1. Status, progress, and assignee are edited from
/// TaskDetailsScreen instead of here, matching what the backend's
/// UpdateTaskRequest actually accepts on PUT /tasks/{id}.
class CreateEditTaskScreen extends ConsumerStatefulWidget {
  const CreateEditTaskScreen({super.key, this.taskId});

  final String? taskId;

  bool get isEditing => taskId != null;

  @override
  ConsumerState<CreateEditTaskScreen> createState() => _CreateEditTaskScreenState();
}

class _CreateEditTaskScreenState extends ConsumerState<CreateEditTaskScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  String _priority = 'medium';
  String _status = 'pending';
  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;
  String? _meetingId;
  bool _assignToMe = false;

  bool _hydrated = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(TaskEntity task) {
    if (_hydrated) return;
    _title.text = task.title;
    _description.text = task.description ?? '';
    _priority = task.priority;
    final deadline = task.deadline;
    if (deadline != null) {
      _deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
      _deadlineTime = TimeOfDay(hour: deadline.hour, minute: deadline.minute);
    }
    _meetingId = task.meetingId;
    _hydrated = true;
  }

  DateTime? get _combinedDeadline {
    if (_deadlineDate == null) return null;
    final time = _deadlineTime ?? const TimeOfDay(hour: 9, minute: 0);
    return DateTime(_deadlineDate!.year, _deadlineDate!.month, _deadlineDate!.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _deadlineDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _deadlineTime ?? TimeOfDay.now());
    if (picked != null) setState(() => _deadlineTime = picked);
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (widget.isEditing) {
        await ref.read(taskDetailsControllerProvider(widget.taskId!).notifier).updateProfile(
              title: _title.text.trim(),
              description: _description.text.trim(),
              priority: _priority,
              deadline: _combinedDeadline,
              meetingId: _meetingId,
            );
      } else {
        final assigneeId = _assignToMe ? ref.read(authControllerProvider).valueOrNull?.id : null;
        await ref.read(createTaskUseCaseProvider)(
          title: _title.text.trim(),
          description: _description.text.trim(),
          priority: _priority,
          status: _status,
          deadline: _combinedDeadline,
          meetingId: _meetingId,
          assignedUserId: assigneeId,
        );
        ref.read(tasksListControllerProvider.notifier).refresh();
      }

      if (mounted) context.pop();
    } catch (e) {
      final failure = e is ApiFailure ? e : ApiFailure.unknown(e.toString());
      setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final task = ref.watch(taskDetailsControllerProvider(widget.taskId!));
      return task.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(child: Text(error is ApiFailure ? error.message : 'Could not load task.')),
        ),
        data: (t) {
          _hydrate(t);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    final meetings = ref.watch(meetingsListControllerProvider).valueOrNull?.items ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit task' : 'New task')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: Spacing.md),
              ],
              TextField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: Spacing.md),
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: [
                  for (final p in _priorities)
                    DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1))),
                ],
                onChanged: (value) => setState(() => _priority = value ?? _priority),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: Spacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Starting status'),
                  items: [
                    for (final s in _createStatuses)
                      DropdownMenuItem(value: s, child: Text(s.replaceAll('_', ' '))),
                  ],
                  onChanged: (value) => setState(() => _status = value ?? _status),
                ),
              ],
              const SizedBox(height: Spacing.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(
                        _deadlineDate == null ? 'Deadline date' : DateFormat.yMMMd().format(_deadlineDate!),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deadlineDate == null ? null : _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_deadlineTime == null ? 'Time' : _deadlineTime!.format(context)),
                    ),
                  ),
                  if (_deadlineDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _deadlineDate = null;
                        _deadlineTime = null;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              DropdownButtonFormField<String?>(
                initialValue: _meetingId,
                decoration: const InputDecoration(labelText: 'Link to meeting (optional)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  for (final meeting in meetings)
                    DropdownMenuItem<String?>(value: meeting.id, child: Text(meeting.title)),
                ],
                onChanged: (value) => setState(() => _meetingId = value),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: Spacing.sm),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _assignToMe,
                  title: const Text('Assign to me'),
                  onChanged: (value) => setState(() => _assignToMe = value ?? false),
                ),
              ],
              const SizedBox(height: Spacing.xl),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditing ? 'Save changes' : 'Create task'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
