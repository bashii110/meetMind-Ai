import 'package:flutter/material.dart';

/// DESIGN.md 6 shared widget library. Renders any status string
/// (meeting status, task status, invite status...) as a small colored
/// pill. Colors are looked up by exact string match, with a neutral
/// fallback so new statuses degrade gracefully instead of crashing.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  static const _colors = <String, Color>{
    'draft': Color(0xFF9E9E9E),
    'scheduled': Color(0xFF2196F3),
    'completed': Color(0xFF4CAF50),
    'cancelled': Color(0xFFF44336),
    'pending': Color(0xFFFF9800),
    'accepted': Color(0xFF4CAF50),
    'declined': Color(0xFFF44336),
    'in_progress': Color(0xFF2196F3),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status] ?? Theme.of(context).colorScheme.outline;
    final label = status.replaceAll('_', ' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
