import 'package:flutter/material.dart';

import '../../../../../../core/theme/spacing.dart';

/// Shown when a meeting has no recording yet — DESIGN.md 2.4's
/// "illustrated (not just text)" empty-state pattern, reusing the same
/// Material-icon-as-placeholder-illustration approach as EmptyState.
class AiEmptyState extends StatelessWidget {
  const AiEmptyState({super.key, required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: Spacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: Spacing.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shown while the AI pipeline is running for this meeting — DESIGN.md
/// 3.5: processing happens in the background, so this is reassuring
/// rather than a blocking spinner the user has to wait out.
class AiProcessingState extends StatelessWidget {
  const AiProcessingState({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3, color: scheme.tertiary),
            ),
            const SizedBox(height: Spacing.md),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: Spacing.xs),
            Text(
              'This runs in the background — feel free to check back later.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class AiFailedState extends StatelessWidget {
  const AiFailedState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: scheme.error),
            const SizedBox(height: Spacing.md),
            Text('Processing failed', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.xs),
            Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
