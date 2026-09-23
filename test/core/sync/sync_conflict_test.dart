import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/core/sync/sync_conflict.dart';

void main() {
  test('round-trips through toJson/fromJson', () {
    final conflict = SyncConflict(
      id: 'c1',
      taskId: 't1',
      localChanges: const {'title': 'My edit', 'priority': 'high'},
      serverSnapshot: const {
        'title': 'Their edit',
        'priority': 'low',
        'updated_at': '2026-01-02T00:00:00.000Z',
      },
      detectedAt: DateTime.utc(2026, 1, 2, 8),
    );

    final restored = SyncConflict.fromJson(conflict.toJson());

    expect(restored.id, 'c1');
    expect(restored.taskId, 't1');
    expect(restored.localChanges, conflict.localChanges);
    expect(restored.serverSnapshot, conflict.serverSnapshot);
    expect(restored.detectedAt, conflict.detectedAt);
  });
}
