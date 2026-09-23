import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_filters.dart';

void main() {
  group('toQueryParameters', () {
    test('an empty filter set sends nothing', () {
      expect(TaskFilters.empty.toQueryParameters(), isEmpty);
    });

    test('includes every field that is set, and only those', () {
      const filters = TaskFilters(status: 'pending', priority: 'high', assignedToMe: true, search: 'report');

      expect(filters.toQueryParameters(), {
        'status': 'pending',
        'priority': 'high',
        'assigned_to_me': true,
        'search': 'report',
      });
    });

    test('drops an empty search string', () {
      const filters = TaskFilters(search: '');
      expect(filters.toQueryParameters(), isEmpty);
    });

    test('a false assignedToMe is omitted, not sent as false', () {
      const filters = TaskFilters(assignedToMe: false);
      expect(filters.toQueryParameters().containsKey('assigned_to_me'), isFalse);
    });
  });

  group('copyWith', () {
    test('a clear flag wins even when a replacement value is also passed', () {
      const filters = TaskFilters(status: 'pending');
      final cleared = filters.copyWith(status: 'completed', clearStatus: true);
      expect(cleared.status, isNull);
    });

    test('fields not touched by copyWith are preserved', () {
      const filters = TaskFilters(status: 'pending', priority: 'high');
      final updated = filters.copyWith(search: 'x');

      expect(updated.status, 'pending');
      expect(updated.priority, 'high');
      expect(updated.search, 'x');
    });
  });
}
