import 'package:equatable/equatable.dart';

/// SRD FR-12.1: "search across meeting titles, transcripts, tasks, users,
/// dates, tags, and AI summaries." Rather than a rigid entity per source,
/// every hit is a `SearchResult` carrying [matchedIn] — a short label
/// telling the user *where* their query matched (title, transcript,
/// summary, description, tag, email) — which covers all of those sources
/// without a combinatorial explosion of result types.
enum SearchResultType { meeting, task, user }

class SearchResult extends Equatable {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    this.subtitle,
    this.matchedIn,
    this.date,
  });

  final SearchResultType type;
  final String id;
  final String title;

  /// A short matched snippet or secondary line — e.g. a transcript
  /// excerpt, the meeting a task belongs to, or a user's email.
  final String? subtitle;

  /// Where the query matched: title | transcript | summary | description
  /// | tag | email. Null when the backend doesn't report it.
  final String? matchedIn;

  final DateTime? date;

  @override
  List<Object?> get props => [type, id, title, subtitle, matchedIn, date];
}
