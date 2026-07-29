import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../providers/ping_provider.dart';

/// Placeholder for DESIGN.md 3.3's Home Dashboard. Phase 0 only needs to
/// prove client <-> server connectivity, so this renders the /ping result;
/// Phase 2+ replaces the body with the real greeting header, meeting
/// carousel, task stats, AI summaries list, calendar widget, and insights
/// card described in DESIGN.md.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ping = ref.watch(pingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('MeetMind AI')),
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.xl),
              child: ping.when(
                data: (message) => _StatusRow(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  title: 'Backend reachable',
                  subtitle: 'GET /api/v1/ping → "$message"',
                ),
                error: (error, _) => _StatusRow(
                  icon: Icons.error,
                  color: Theme.of(context).colorScheme.error,
                  title: 'Could not reach backend',
                  subtitle: error is ApiFailure
                      ? error.message
                      : 'Check API_BASE_URL and that `php artisan serve` is running.',
                ),
                loading: () => const _StatusRow(
                  icon: null,
                  color: null,
                  title: 'Checking backend…',
                  subtitle: 'GET /api/v1/ping',
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData? icon;
  final Color? color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon == null
            ? const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : Icon(icon, color: color, size: 32),
        const SizedBox(height: Spacing.md),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: Spacing.xs),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
