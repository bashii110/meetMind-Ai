import '../../domain/entities/moderation_item.dart';

class ModerationItemModel extends ModerationItem {
  const ModerationItemModel({
    required super.id,
    required super.contentType,
    required super.contentId,
    required super.contentSnippet,
    required super.reportedByName,
    required super.reason,
    required super.status,
    required super.reportedAt,
  });

  factory ModerationItemModel.fromJson(Map<String, dynamic> json) {
    final reportedBy = json['reported_by'] as Map<String, dynamic>?;

    return ModerationItemModel(
      id: json['id'].toString(),
      contentType: json['content_type'] as String? ?? '',
      contentId: json['content_id']?.toString() ?? '',
      contentSnippet: json['content_snippet'] as String? ?? '',
      reportedByName: reportedBy?['name'] as String? ?? 'Someone',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      reportedAt: DateTime.parse(json['reported_at'] as String),
    );
  }
}

class PaginatedModerationItemsModel extends PaginatedModerationItems {
  const PaginatedModerationItemsModel({
    required super.items,
    required super.currentPage,
    required super.lastPage,
    required super.total,
  });

  factory PaginatedModerationItemsModel.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List? ?? const [])
        .map((e) => ModerationItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = json['meta'] as Map<String, dynamic>? ?? const {};

    return PaginatedModerationItemsModel(
      items: items,
      currentPage: meta['current_page'] as int? ?? 1,
      lastPage: meta['last_page'] as int? ?? 1,
      total: meta['total'] as int? ?? items.length,
    );
  }
}
