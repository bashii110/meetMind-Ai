import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/workspace_details_controller.dart';
import '../providers/workspace_providers.dart';
import '../providers/workspaces_list_controller.dart';

/// Pass [workspaceId] to edit an existing workspace, or leave it null to
/// create a new one — SRD FR-10.1. Editing is only reachable from
/// `WorkspaceDetailsScreen` when `Workspace.canManage` is true.
class CreateEditWorkspaceScreen extends ConsumerStatefulWidget {
  const CreateEditWorkspaceScreen({super.key, this.workspaceId});

  final String? workspaceId;

  bool get isEditing => workspaceId != null;

  @override
  ConsumerState<CreateEditWorkspaceScreen> createState() => _CreateEditWorkspaceScreenState();
}

class _CreateEditWorkspaceScreenState extends ConsumerState<CreateEditWorkspaceScreen> {
  final _name = TextEditingController();
  final _description = TextEditingController();

  bool _hydrated = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _hydrate(String name, String? description) {
    if (_hydrated) return;
    _name.text = name;
    _description.text = description ?? '';
    _hydrated = true;
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (widget.isEditing) {
        await ref.read(workspaceDetailsControllerProvider(widget.workspaceId!).notifier).updateDetails(
              name: _name.text.trim(),
              description: _description.text.trim(),
            );
      } else {
        await ref.read(createWorkspaceUseCaseProvider)(
          name: _name.text.trim(),
          description: _description.text.trim(),
        );
        await ref.read(workspacesListControllerProvider.notifier).refresh();
      }

      if (mounted) context.pop();
    } catch (e) {
      final failure = ApiFailure.from(e);
      if (mounted) setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final workspace = ref.watch(workspaceDetailsControllerProvider(widget.workspaceId!));
      return workspace.when(
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (error, _) => Scaffold(body: Center(child: Text(ApiFailure.from(error).message))),
        data: (w) {
          _hydrate(w.name, w.description);
          return _buildForm(context);
        },
      );
    }
    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Edit workspace' : 'New workspace')),
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
                controller: _name,
                decoration: const InputDecoration(labelText: 'Workspace name'),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _description,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: Spacing.xl),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEditing ? 'Save changes' : 'Create workspace'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
