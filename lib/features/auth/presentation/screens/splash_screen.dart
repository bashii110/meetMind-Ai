import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';

/// DESIGN.md 3.1: "Splash: logo + tagline, brief brand animation."
///
/// Real logic (check stored token validity, fetch current user, decide
/// authenticated vs unauthenticated) lands with the auth feature in Phase 1.
/// For now this just renders the brand moment and lets the router redirect.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 56, color: scheme.primary),
            const SizedBox(height: 16),
            Text(
              'MeetMind AI',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Meetings, summarized. Tasks, tracked.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            TextButton(
              onPressed: () => context.go(AppRoutes.dashboard),
              child: const Text('Continue (dev shortcut)'),
            ),
          ],
        ),
      ),
    );
  }
}
