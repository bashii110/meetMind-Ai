import 'package:flutter/material.dart';

/// DESIGN.md 3.4: "participant avatars (stacked)."
class AvatarStack extends StatelessWidget {
  const AvatarStack({super.key, required this.names, this.max = 4, this.radius = 14});

  final List<String> names;
  final int max;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final shown = names.take(max).toList();
    final overflow = names.length - shown.length;
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: radius * 2,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * (radius * 1.3),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: scheme.primaryContainer,
                child: Text(
                  shown[i].isNotEmpty ? shown[i][0].toUpperCase() : '?',
                  style: TextStyle(fontSize: radius * 0.8, color: scheme.onPrimaryContainer),
                ),
              ),
            ),
          if (overflow > 0)
            Positioned(
              left: shown.length * (radius * 1.3),
              child: CircleAvatar(
                radius: radius,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Text('+$overflow', style: TextStyle(fontSize: radius * 0.7)),
              ),
            ),
        ],
      ),
    );
  }
}
