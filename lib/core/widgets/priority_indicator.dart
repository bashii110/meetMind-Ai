import 'package:flutter/material.dart';

/// DESIGN.md 3.7: "priority color-strip." A small filled dot + label,
/// reused by meeting cards now and task cards from Phase 5 onward.
class PriorityIndicator extends StatelessWidget {
  const PriorityIndicator({super.key, required this.priority});

  final String priority;

  static const _colors = <String, Color>{
    'low': Color(0xFF4CAF50),
    'medium': Color(0xFFFF9800),
    'high': Color(0xFFF44336),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[priority] ?? Theme.of(context).colorScheme.outline;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          priority[0].toUpperCase() + priority.substring(1),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
