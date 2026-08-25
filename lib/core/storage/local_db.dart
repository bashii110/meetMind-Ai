import 'package:hive_flutter/hive_flutter.dart';

/// Local source-of-truth setup (ARCHITECTURE.md 2.3, Offline-First Strategy).
///
/// Each feature registers its own Hive box name + adapters here as they're
/// built, e.g.:
///   Hive.registerAdapter(MeetingModelAdapter());
///   await Hive.openBox<MeetingModel>(HiveBoxes.meetings);
class HiveBoxes {
  HiveBoxes._();

  static const meetings = 'meetings_box';
  static const tasks = 'tasks_box';
  static const transcriptsCache = 'transcripts_cache_box';
  static const String audioUploads = 'audio_uploads';

  /// Offline mutation queue (outbox pattern) — created meetings, task edits,
  /// etc. made while offline, replayed on reconnect.
  static const outbox = 'outbox_box';

  /// Locally-recorded audio queued for chunked upload (Phase 3,
  /// ARCHITECTURE.md 2.4) — survives app restarts so an interrupted
  /// upload can resume instead of being lost. See
  /// features/recording/data/datasources/pending_upload_local_data_source.dart.
  static const pendingUploads = 'pending_uploads_box';
}

Future<void> initLocalDb() async {
  await Hive.initFlutter();

  // Pending audio uploads are opened eagerly since Phase 3's recording
  // flow depends on them from app start (main.dart's resumeAll() call).
  // Other boxes (meetings/tasks caches, outbox) get opened by their own
  // feature's data layer as those phases land — register adapters + open
  // boxes per feature as they're implemented, e.g.:
  // await Hive.openBox(HiveBoxes.meetings);
  // await Hive.openBox(HiveBoxes.tasks);
  // await Hive.openBox(HiveBoxes.outbox);
  await Hive.openBox(HiveBoxes.pendingUploads);
}
