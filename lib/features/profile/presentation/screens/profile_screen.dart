import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmind_ai/features/profile/presentation/providers/profile_controller.dart';

import '../../../../../../core/network/api_failure.dart';
import '../../../../../../core/theme/spacing.dart';


class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _bio = TextEditingController();
  final _company = TextEditingController();
  final _position = TextEditingController();
  final _newSkill = TextEditingController();

  List<String> _skills = [];
  XFile? _pickedAvatar;

  // Tracks *which user's* data the form was last hydrated from, rather
  // than a one-shot bool. A plain bool would only ever hydrate once per
  // widget instance and then never again — harmless for a fresh
  // navigation (a new State is created each time), but fragile the
  // moment this screen is kept alive across a logout/login (e.g. behind
  // a bottom-nav IndexedStack), where it would keep showing the previous
  // user's form values even after the underlying data changed.
  String? _hydratedUserId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    _company.dispose();
    _position.dispose();
    _newSkill.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) setState(() => _pickedAvatar = file);
  }

  void _addSkill() {
    final skill = _newSkill.text.trim();
    if (skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills = [..._skills, skill];
      _newSkill.clear();
    });
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref.read(profileControllerProvider.notifier).updateProfile(
            name: _name.text.trim(),
            bio: _bio.text.trim(),
            company: _company.text.trim(),
            position: _position.text.trim(),
            skills: _skills,
            avatar: _pickedAvatar,
          );

      if (mounted) {
        setState(() => _pickedAvatar = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
      }
    } catch (e) {
      // ApiFailure.from unwraps DioException.error correctly — checking
      // `e is ApiFailure` directly here is always false.
      final failure = ApiFailure.from(e);
      setState(() => _error = failure.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileControllerProvider);

    // Populate the form once per user, from whichever load finishes first
    // — avoid clobbering in-progress edits on every provider rebuild, but
    // do re-hydrate if the underlying user actually changed.
    profile.whenData((user) {
      if (_hydratedUserId != user.id) {
        _name.text = user.name;
        _bio.text = user.bio ?? '';
        _company.text = user.company ?? '';
        _position.text = user.position ?? '';
        _skills = user.skills;
        _hydratedUserId = user.id;
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.xl),
            child: Text(ApiFailure.from(error).message),
          ),
        ),
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _pickedAvatar != null
                            ? FileImage(File(_pickedAvatar!.path)) as ImageProvider
                            : (user.avatar != null ? NetworkImage(user.avatar!) : null),
                        child: _pickedAvatar == null && user.avatar == null
                            ? const Icon(Icons.person, size: 40)
                            : null,
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: Spacing.xl),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: Spacing.md),
              ],
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: Spacing.md),
              Text('Email', style: Theme.of(context).textTheme.labelMedium),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                child: Text(user.email), // email is not editable here — Phase 1 doesn't cover email-change flow
              ),
              const SizedBox(height: Spacing.sm),
              TextField(
                controller: _company,
                decoration: const InputDecoration(labelText: 'Company'),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _position,
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              const SizedBox(height: Spacing.md),
              TextField(
                controller: _bio,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: Spacing.lg),
              Text('Skills', style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: Spacing.sm),
              Wrap(
                spacing: Spacing.sm,
                runSpacing: Spacing.sm,
                children: [
                  for (final skill in _skills)
                    Chip(
                      label: Text(skill),
                      onDeleted: () => setState(() => _skills = _skills.where((s) => s != skill).toList()),
                    ),
                ],
              ),
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSkill,
                      decoration: const InputDecoration(labelText: 'Add a skill'),
                      onSubmitted: (_) => _addSkill(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.add), onPressed: _addSkill),
                ],
              ),
              const SizedBox(height: Spacing.xl),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
