/// Mirrors MeetingRepository::forUser's $filters shape on the backend.
/// DESIGN.md 3.4: "filter chips (status, category, tag) + search bar."
class MeetingFilters {
  const MeetingFilters({this.status, this.category, this.tag, this.search});

  final String? status;
  final String? category;
  final String? tag;
  final String? search;

  static const empty = MeetingFilters();

  bool get isEmpty => status == null && category == null && tag == null && search == null;

  Map<String, dynamic> toQueryParameters() => {
        if (status != null) 'status': status,
        if (category != null) 'category': category,
        if (tag != null) 'tag': tag,
        if (search != null && search!.isNotEmpty) 'search': search,
      };

  MeetingFilters copyWith({
    String? status,
    bool clearStatus = false,
    String? category,
    bool clearCategory = false,
    String? tag,
    bool clearTag = false,
    String? search,
    bool clearSearch = false,
  }) {
    return MeetingFilters(
      status: clearStatus ? null : (status ?? this.status),
      category: clearCategory ? null : (category ?? this.category),
      tag: clearTag ? null : (tag ?? this.tag),
      search: clearSearch ? null : (search ?? this.search),
    );
  }
}
