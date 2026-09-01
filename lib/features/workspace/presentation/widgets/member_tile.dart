import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workspace_member.dart';
import 'role_chip.dart';

/// DESIGN.md shared widget conventions. [canManage] gates the trailing
/// popup menu (change role / assign department / remove) — SRD FR-10.2:
/// only workspace owners/admins may manage other members. The owner
/// themself never gets a menu (there's no action to take on them from
/// this screen — ownership transfer is out of scope for Phase 7).
class MemberTile extends StatelessWidget {
  const MemberTile({
    super.key,
    required this.member,
    required this.canManage,
    this.onChangeRole,
    this.onAssignDepartment,
    this.onRemove,
  });

  final WorkspaceMember member;
  final bool canManage;
  final VoidCallback? onChangeRole;
  final VoidCallback? onAssignDepartment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final showMenu = canManage && member.role != WorkspaceRole.owner;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        child: Text(member.name.isNotEmpty ? member.name[0].toUpperCase() : '?'),
      ),
      title: Text(member.name),
      subtitle: Text(
        member.departmentName != null ? '${member.email} · ${member.departmentName}' : member.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RoleChip(role: member.role.apiValue),
          if (showMenu)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                switch (value) {
                  case 'role':
                    onChangeRole?.call();
                  case 'department':
                    onAssignDepartment?.call();
                  case 'remove':
                    onRemove?.call();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'role', child: Text('Change role')),
                PopupMenuItem(value: 'department', child: Text('Assign department')),
                PopupMenuItem(value: 'remove', child: Text('Remove from workspace')),
              ],
            )
          else
            const SizedBox(width: Spacing.md),
        ],
      ),
    );
  }
}
