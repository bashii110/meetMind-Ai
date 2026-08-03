import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/chip_input_field.dart';
import '../../domain/entities/meeting.dart';
import '../providers/meeting_details_controller.dart';
import '../providers/meeting_providers.dart';
import '../providers/meetings_list_controller.dart';

const _priorities = ['low', 'medium', 'high'];
final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Pass [meetingId] to edit an existing meeting, or leave it null to create
/// a new one — SRD FR-3.1.
class CreateEditMeetingScreen extends ConsumerStatefulWidget {
  const CreateEditMeetingScreen({super.key, this.meetingId});

  final String? meetingId;

  bool get isEditing => meetingId != null;

  @override
  ConsumerState<CreateEditMeetingScreen> createState() => _CreateEditMeetingScreenState();
}

class _CreateEditMeetingScreenState extends ConsumerState<CreateEditMeetingScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _onlineLink = TextEditingController();
  final _category = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  String _priority = 'medium';
  List<String> _tags = [];
  List<String> _participantEmails = [];

  bool _hydrated = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _onlineLink.dispose();
    _category.dispose();
    super.dispose();
  }

  void _hydrate(Meeting meeting) {
    if (_hydrated) return;
    _title.text = meeting.title;
    _description.text = meeting.description ?? '';
    _location.text = meeting.location ?? '';
    _onlineLink.text = meeting.onlineLink ?? '';
    _category.text = meeting.category ?? '';
    _date = meeting.date;
    _priority = meeting.priority;
    _tags = meeting.tags;
    if (meeting.time != null) {
      final parts = meeting.time!.split(':');
      if (parts.length >= 2) {
        _time = TimeOfDay(hour: int.tryParse(parts[0]) ?? 0, minute: int.tryParse(parts[1]) ?? 0);
      }
    }
    _hydrated = true;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time ?? TimeOfDay.now());
    if (picked != null) setState(() => _time = picked);
  }

  String? _formattedTime() {
    if (_time == null) return null;
    return '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _date == null) {
      setState(() => _error = 'Title and date are required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (widget.isEditing) {
        await ref.read(meetingDetailsControllerProvider(widget.meetingId!).notifier).updateProfile(
              title: _title.text.trim(),
              description: _description.text.trim(),
              date: _date,
              time: _formattedTime(),
              location: _location.text.trim(),
              onlineLink: _onlineLink.text.trim(),
              priority: _priority,
              category: _category.text.trim(),
              tags: _tags,
            );
      } else {
        await ref.read(createMeetingUseCaseProvider)(
          title: _title.text.trim(),
          description: _description.text.trim(),
          date: _date!,
          time: _formattedTime(),
          location: _location.text.trim(),
          onlineLink: _onlineLink.text.trim(),
          priority: _priority,
          category: _category.text.trim(),
          tags: _tags,
          participantEmails: _participantEmails,
        );
        ref.read(meetingsListControllerProvider.notifier).refresh();
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
      final meeting = ref.watch(meetingDetailsControllerProvider(widget.meetingId!));
      return meeting.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(
          body: Center(child: Text(error is ApiFailure ? error.message : 'Could not load meeting.')),
        ),
        data: (m) {
          _hydrate(m);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit meeting' : 'New meeting')),
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
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 18),
                      label: Text(_date == null ? 'Pick date' : DateFormat.yMMMd().format(_date!)),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(_formattedTime() ?? 'Pick time'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _onlineLink,
                decoration: const InputDecoration(labelText: 'Online meeting link'),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category'),
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
              const SizedBox(height: Spacing.lg),
              ChipInputField(
                label: 'Add a tag',
                values: _tags,
                onChanged: (values) => setState(() => _tags = values),
              ),
              if (!widget.isEditing) ...[
                const SizedBox(height: Spacing.lg),
                Text('Participants', style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: Spacing.sm),
                ChipInputField(
                  label: 'Invite by email',
                  values: _participantEmails,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => _emailPattern.hasMatch(v) ? null : 'Enter a valid email',
                  onChanged: (values) => setState(() => _participantEmails = values),
                ),
              ],
              const SizedBox(height: Spacing.xl),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Create meeting'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
