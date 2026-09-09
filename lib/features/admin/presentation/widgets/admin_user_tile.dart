import 'package:flutter/material.dart';

import '../../domain/entities/admin_user.dart';

/// SRD FR-16.1. [onToggleDisabled] is null when acting on the signed-in
/// admin's own account isn't allowed (see AdminScreen's Users tab — an
/// admin disabling themselves would lock them out of the screen they're
/// using to manage everyone else's).
class AdminUserTile extends StatelessWidget {
  const AdminUserTile({super.key, required this.user, this.onToggleDisabled});

  final AdminUser user;
  final VoidCallback? onToggleDisabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isDisabled ? scheme.errorContainer : scheme.primaryContainer,
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
          style: TextStyle(color: user.isDisabled ? scheme.onErrorContainer : scheme.onPrimaryContainer),
        ),
      ),
      title: Text(
        user.name,
        style: user.isDisabled
            ? TextStyle(decoration: TextDecoration.lineThrough, color: scheme.onSurfaceVariant)
            : null,
      ),
      subtitle: Text('${user.email} · ${user.role.replaceAll('_', ' ')}'),
      trailing: onToggleDisabled == null
          ? null
          : Switch(
              value: !user.isDisabled,
              onChanged: (_) => onToggleDisabled!(),
            ),
    );
  }
}
