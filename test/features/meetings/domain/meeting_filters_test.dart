import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_filters.dart';

void main() {
  test('isEmpty is true only when every field is unset', () {
    expect(MeetingFilters.empty.isEmpty, isTrue);
    expect(const MeetingFilters(status: 'draft').isEmpty, isFalse);
  });

  test('toQueryParameters includes only set fields and drops an empty search', () {
    const filters = MeetingFilters(status: 'scheduled', tag: 'urgent', search: '');
    expect(filters.toQueryParameters(), {'status': 'scheduled', 'tag': 'urgent'});
  });

  test('a clear flag wins over a simultaneous replacement value', () {
    const filters = MeetingFilters(category: 'standup');
    final cleared = filters.copyWith(category: 'retro', clearCategory: true);
    expect(cleared.category, isNull);
  });
}
