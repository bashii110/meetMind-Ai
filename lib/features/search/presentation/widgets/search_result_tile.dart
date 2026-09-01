import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/search_result.dart';

/// One row in the search results list — DESIGN.md shared widget
/// conventions. [SearchResult.matchedIn] renders as a small trailing
/// label so the user can tell whether their query hit a title, a
/// transcript line, a tag, etc. (SRD FR-12.1).
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({super.key, required this.result, required this.onTap});

  final SearchResult result;
  final VoidCallback onTap;

  IconData get _icon => switch (result.type) {
        SearchResultType.meeting => Icons.event_outlined,
        SearchResultType.task => Icons.check_circle_outline,
        SearchResultType.user => Icons.person_outline,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Icon(_icon, size: 18, color: scheme.onSurfaceVariant),
      ),
      title: Text(result.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: result.subtitle != null
          ? Text(result.subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis)
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (result.date != null)
            Text(DateFormat.MMMd().format(result.date!), style: Theme.of(context).textTheme.labelSmall),
          if (result.matchedIn != null)
            Text(
              'in ${result.matchedIn}',
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
        ],
      ),
      onTap: onTap,
    );
  }
}
