import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:meetmind_ai/core/storage/local_db.dart';
import 'package:meetmind_ai/core/sync/outbox_entry.dart';
import 'package:meetmind_ai/core/sync/sync_conflict.dart';
import 'package:meetmind_ai/core/widgets/sync_status_chip.dart';

/// Exercises SyncStatusChip against a *real* (temp-dir) Hive store rather
/// than mocking OutboxSyncManager — it reads the outbox/conflict boxes
/// directly in its build(), so this is closer to an integration test of
/// the actual Phase 10 wiring than a unit test with everything faked out.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('meetmind_hive_test');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveBoxes.outbox);
    await Hive.openBox(HiveBoxes.syncConflicts);
    await Hive.openBox(HiveBoxes.meetings);
    await Hive.openBox(HiveBoxes.tasks);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Widget wrap() => const ProviderScope(child: MaterialApp(home: Scaffold(body: SyncStatusChip())));

  testWidgets('renders nothing when both queues are empty', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an upload badge with the pending count', (tester) async {
    final box = Hive.box(HiveBoxes.outbox);
    await box.put(
      'e1',
      OutboxEntry(
        id: 'e1',
        entityType: OutboxEntityType.task,
        operation: OutboxOperation.update,
        localId: 't1',
        payload: const {'title': 'Offline edit'},
        createdAt: DateTime.now(),
      ).toJson(),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.cloud_upload_outlined), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('shows a conflict badge (taking priority over the pending badge)', (tester) async {
    final outboxBox = Hive.box(HiveBoxes.outbox);
    await outboxBox.put(
      'e1',
      OutboxEntry(
        id: 'e1',
        entityType: OutboxEntityType.task,
        operation: OutboxOperation.update,
        localId: 't1',
        payload: const {'title': 'Offline edit'},
        createdAt: DateTime.now(),
      ).toJson(),
    );

    final conflictBox = Hive.box(HiveBoxes.syncConflicts);
    await conflictBox.put(
      'c1',
      SyncConflict(
        id: 'c1',
        taskId: 't1',
        localChanges: const {'title': 'Mine'},
        serverSnapshot: const {'title': 'Theirs'},
        detectedAt: DateTime.now(),
      ).toJson(),
    );

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync_problem), findsOneWidget);
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNothing);
  });
}
