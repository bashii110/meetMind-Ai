import 'package:flutter/material.dart';

import '../../../../core/theme/spacing.dart';
import '../../domain/entities/workspace.dart';
import 'role_chip.dart';

/// DESIGN.md 6 shared widget library conventions, scoped to this feature.
class WorkspaceCard extends StatelessWidget {
  const WorkspaceCard({super.key, required this.workspace, required this.onTap});

  final Workspace workspace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Text(
                      workspace.name.isNotEmpty ? workspace.name[0].toUpperCase() : '?',
                      style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      workspace.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RoleChip(role: workspace.myRole),
                ],
              ),
              if (workspace.description != null && workspace.description!.isNotEmpty) ...[
                const SizedBox(height: Spacing.sm),
                Text(
                  workspace.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              const SizedBox(height: Spacing.sm),
              Row(
                children: [
                  Icon(Icons.people_outline, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${workspace.memberCount} member${workspace.memberCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: Spacing.md),
                  Icon(Icons.person_outline, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      workspace.ownerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
