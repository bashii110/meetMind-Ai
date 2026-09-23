import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/sync/outbox_entry.dart';

void main() {
  test('round-trips through toJson/fromJson, including optional fields', () {
    final entry = OutboxEntry(
      id: 'e1',
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.update,
      localId: 't1',
      payload: const {'title': 'New title', 'priority': 'high'},
      createdAt: DateTime.utc(2026, 1, 1, 12),
      baseUpdatedAt: DateTime.utc(2026, 1, 1, 10),
      retryCount: 2,
      lastError: 'timeout',
    );

    final restored = OutboxEntry.fromJson(entry.toJson());

    expect(restored.id, entry.id);
    expect(restored.entityType, OutboxEntityType.task);
    expect(restored.operation, OutboxOperation.update);
    expect(restored.localId, 't1');
    expect(restored.payload, {'title': 'New title', 'priority': 'high'});
    expect(restored.createdAt, entry.createdAt);
    expect(restored.baseUpdatedAt, entry.baseUpdatedAt);
    expect(restored.retryCount, 2);
    expect(restored.lastError, 'timeout');
  });

  test('baseUpdatedAt/lastError stay null when never set', () {
    final entry = OutboxEntry(
      id: 'e2',
      entityType: OutboxEntityType.meeting,
      operation: OutboxOperation.create,
      localId: 'local_abc',
      payload: const {'title': 'New meeting'},
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final restored = OutboxEntry.fromJson(entry.toJson());

    expect(restored.baseUpdatedAt, isNull);
    expect(restored.lastError, isNull);
    expect(restored.retryCount, 0);
  });

  test('copyWith updates retryCount/lastError without touching the rest', () {
    final entry = OutboxEntry(
      id: 'e3',
      entityType: OutboxEntityType.task,
      operation: OutboxOperation.delete,
      localId: 't3',
      payload: const {},
      createdAt: DateTime.utc(2026, 1, 1),
    );

    final retried = entry.copyWith(retryCount: 1, lastError: 'connection error');

    expect(retried.id, entry.id);
    expect(retried.localId, entry.localId);
    expect(retried.retryCount, 1);
    expect(retried.lastError, 'connection error');
  });
}
