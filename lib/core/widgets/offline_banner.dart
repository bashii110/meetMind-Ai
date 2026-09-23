import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meetmind_ai/core/network/connectivity_controller.dart';

/// A slim, persistent bar shown above the whole app whenever
/// [isOnlineProvider] is false. DESIGN.md doesn't spell out an offline
/// treatment explicitly, so this follows the same "non-intrusive,
/// non-blocking" spirit as the existing AI-processing snackbar/badge
/// pattern (DESIGN.md's animation table) rather than a blocking dialog —
/// the person can keep using the app while it's shown.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    if (online) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.cloud_off, size: 16, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "You're offline — changes will sync when you're back online.",
                  style: TextStyle(fontSize: 12, color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
