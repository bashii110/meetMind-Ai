import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline }

/// Wraps `connectivity_plus`'s stream into a single online/offline signal
/// the rest of the app can watch — repositories fall back to cache when
/// offline, and OutboxSyncManager triggers a sync pass when this flips
/// back to online. ARCHITECTURE.md 2.3's offline-first strategy needs one
/// source of truth for "are we online right now," rather than each
/// feature calling Connectivity() directly (AudioUploadManager did this
/// ad hoc in Phase 3 — this generalizes that pattern app-wide).
class ConnectivityController extends Notifier<ConnectivityStatus> {
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  ConnectivityStatus build() {
    _sub = Connectivity().onConnectivityChanged.listen((results) {
      state = _resolve(results);
    });
    ref.onDispose(() => _sub?.cancel());

    // Optimistic initial state, refined by refresh() below — main.dart
    // calls it once at startup before anything renders on real data.
    return ConnectivityStatus.online;
  }

  Future<void> refresh() async {
    final results = await Connectivity().checkConnectivity();
    state = _resolve(results);
  }

  ConnectivityStatus _resolve(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none)
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;
  }
}

final connectivityControllerProvider =
    NotifierProvider<ConnectivityController, ConnectivityStatus>(ConnectivityController.new);

final isOnlineProvider = Provider<bool>(
  (ref) => ref.watch(connectivityControllerProvider) == ConnectivityStatus.online,
);
