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

  /// Offline mutation queue (outbox pattern) — created meetings, task edits,
  /// etc. made while offline, replayed on reconnect.
  static const outbox = 'outbox_box';
}

Future<void> initLocalDb() async {
  await Hive.initFlutter();

  // Register adapters + open boxes per feature as they're implemented:
  // await Hive.openBox(HiveBoxes.meetings);
  // await Hive.openBox(HiveBoxes.tasks);
  // await Hive.openBox(HiveBoxes.outbox);
}
