import 'package:flutter/material.dart';

/// Small colored pill for a workspace role string (owner/admin/member) —
/// same visual language as `StatusChip` (core/widgets), kept as its own
/// widget since role colors are semantically distinct from meeting/task
/// status colors and this feature shouldn't reach in and modify a shared
/// core widget's color map.
class RoleChip extends StatelessWidget {
  const RoleChip({super.key, required this.role});

  /// owner | admin | member
  final String role;

  static const _colors = <String, Color>{
    'owner': Color(0xFF9C27B0),
    'admin': Color(0xFF2196F3),
    'member': Color(0xFF4CAF50),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[role] ?? Theme.of(context).colorScheme.outline;
    final label = role.isEmpty ? '' : role[0].toUpperCase() + role.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
