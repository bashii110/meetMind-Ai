import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../domain/entities/search_result.dart';
import '../../domain/entities/search_results.dart';
import '../providers/search_controller.dart';
import '../widgets/search_result_tile.dart';

/// SRD FR-12.1 / PHASES.md Phase 8: "Global search across meetings,
/// transcripts, tasks, users, tags, summaries."
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _openRecent(String query) {
    _controller.text = query;
    _controller.selection = TextSelection.collapsed(offset: query.length);
    ref.read(searchControllerProvider.notifier).selectRecent(query);
  }

  void _openResult(SearchResult result) {
    switch (result.type) {
      case SearchResultType.meeting:
        context.push(AppRoutes.meetingDetailsPath(result.id));
      case SearchResultType.task:
        context.push(AppRoutes.taskDetailsPath(result.id));
      case SearchResultType.user:
        // No "view another user's profile" screen exists yet — Profile is
        // scoped to the signed-in user (see ProfileScreen). A lightweight
        // dialog is enough to surface the match without inventing a route.
        showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(result.title),
            content: Text(result.subtitle ?? ''),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final notifier = ref.read(searchControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Search meetings, tasks, people…',
            border: InputBorder.none,
            suffixIcon: state.query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      notifier.clear();
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onChanged: notifier.onQueryChanged,
        ),
      ),
      body: Column(
        children: [
          if (state.query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.sm),
              child: _FilterChips(filter: state.filter, onChanged: notifier.setFilter),
            ),
          Expanded(
            child: state.query.isEmpty
                ? _RecentSearches(recent: state.recentSearches, onTap: _openRecent)
                : state.results.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Spacing.xl),
                        child: Text(
                          'Search failed. Please try again.',
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    ),
                    data: (results) => _ResultsList(
                      results: results,
                      filter: state.filter,
                      onTap: _openResult,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.filter, required this.onChanged});

  final SearchFilter filter;
  final ValueChanged<SearchFilter> onChanged;

  static const _labels = {
    SearchFilter.all: 'All',
    SearchFilter.meetings: 'Meetings',
    SearchFilter.tasks: 'Tasks',
    SearchFilter.users: 'People',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final f in SearchFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.sm),
              child: FilterChip(
                label: Text(_labels[f]!),
                selected: filter == f,
                onSelected: (_) => onChanged(f),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({required this.recent, required this.onTap});

  final List<String> recent;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search, size: 48, color: scheme.outline),
              const SizedBox(height: Spacing.md),
              Text(
                'Search across meetings, tasks, and people',
                style: TextStyle(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
          child: Text('Recent searches', style: Theme.of(context).textTheme.labelMedium),
        ),
        for (final query in recent)
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(query),
            onTap: () => onTap(query),
          ),
      ],
    );
  }
}

class _ResultsList extends StatelessWidget {
  const _ResultsList({required this.results, required this.filter, required this.onTap});

  final SearchResults results;
  final SearchFilter filter;
  final void Function(SearchResult result) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final showMeetings = filter == SearchFilter.all || filter == SearchFilter.meetings;
    final showTasks = filter == SearchFilter.all || filter == SearchFilter.tasks;
    final showUsers = filter == SearchFilter.all || filter == SearchFilter.users;

    final visibleCount = (showMeetings ? results.meetings.length : 0) +
        (showTasks ? results.tasks.length : 0) +
        (showUsers ? results.users.length : 0);

    if (visibleCount == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off, size: 48, color: scheme.outline),
              const SizedBox(height: Spacing.md),
              Text('No results for "${results.query}"', style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      children: [
        if (showMeetings && results.meetings.isNotEmpty) ...[
          const _SectionHeader(title: 'Meetings'),
          for (final r in results.meetings) SearchResultTile(result: r, onTap: () => onTap(r)),
        ],
        if (showTasks && results.tasks.isNotEmpty) ...[
          const _SectionHeader(title: 'Tasks'),
          for (final r in results.tasks) SearchResultTile(result: r, onTap: () => onTap(r)),
        ],
        if (showUsers && results.users.isNotEmpty) ...[
          const _SectionHeader(title: 'People'),
          for (final r in results.users) SearchResultTile(result: r, onTap: () => onTap(r)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, Spacing.xs),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
