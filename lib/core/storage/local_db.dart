import 'package:hive_flutter/hive_flutter.dart';

/// Local source-of-truth setup (ARCHITECTURE.md 2.3, Offline-First Strategy).
class HiveBoxes {
  HiveBoxes._();

  static const meetings = 'meetings_box';
  static const tasks = 'tasks_box';
  static const transcriptsCache = 'transcripts_cache_box';
  static const String audioUploads = 'audio_uploads';

  /// Offline mutation queue (outbox pattern) — created meetings, task
  /// edits, etc. made while offline, replayed on reconnect. See
  /// core/sync/outbox_sync_manager.dart.
  static const outbox = 'outbox_box';

  /// Locally-recorded audio queued for chunked upload (Phase 3,
  /// ARCHITECTURE.md 2.4) — survives app restarts so an interrupted
  /// upload can resume instead of being lost. See
  /// features/recording/data/datasources/pending_upload_local_data_source.dart.
  static const pendingUploads = 'pending_uploads_box';

  /// Phase 10: task edits made offline whose server copy has since
  /// diverged — held here until the user manually resolves them via
  /// ConflictResolutionScreen. Meetings use last-write-wins instead and
  /// never populate this box.
  static const syncConflicts = 'sync_conflicts_box';
}

Future<void> initLocalDb() async {
  await Hive.initFlutter();

  // Pending audio uploads are opened eagerly since Phase 3's recording
  // flow depends on them from app start (main.dart's resumeAll() call).
  await Hive.openBox(HiveBoxes.pendingUploads);

  // Phase 10: meetings/tasks are now genuinely cache-first (repositories
  // read/write through these before ever touching the network), and the
  // outbox/conflict queues need to be readable the moment the app boots
  // (a sync pass can kick off before any screen has opened), so all four
  // are opened eagerly alongside pendingUploads rather than lazily per
  // feature.
  await Hive.openBox(HiveBoxes.meetings);
  await Hive.openBox(HiveBoxes.tasks);
  await Hive.openBox(HiveBoxes.outbox);
  await Hive.openBox(HiveBoxes.syncConflicts);
}
