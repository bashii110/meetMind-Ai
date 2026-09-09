import 'package:equatable/equatable.dart';

/// SRD FR-16.3: "Admins shall moderate reported content." One entry in
/// the moderation queue — [contentType]/[contentId] point at whatever was
/// reported (a task comment, a meeting description, ...), kept generic
/// the same way `ActivityLogEntry` treats its subject.
class ModerationItem extends Equatable {
  const ModerationItem({
    required this.id,
    required this.contentType,
    required this.contentId,
    required this.contentSnippet,
    required this.reportedByName,
    required this.reason,
    required this.status,
    required this.reportedAt,
  });

  final String id;
  final String contentType;
  final String contentId;
  final String contentSnippet;
  final String reportedByName;
  final String reason;

  /// pending | resolved | dismissed
  final String status;
  final DateTime reportedAt;

  @override
  List<Object?> get props =>
      [id, contentType, contentId, contentSnippet, reportedByName, reason, status, reportedAt];
}

class PaginatedModerationItems {
  const PaginatedModerationItems({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  final List<ModerationItem> items;
  final int currentPage;
  final int lastPage;
  final int total;

  bool get hasMore => currentPage < lastPage;
}
