import '../../domain/entities/paginated_meetings.dart';
import 'meeting_model.dart';

class PaginatedMeetingsModel extends PaginatedMeetings {
  const PaginatedMeetingsModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  factory PaginatedMeetingsModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((e) => MeetingModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return PaginatedMeetingsModel(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
    );
  }
}
