import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/entities/meeting_filters.dart';
import '../providers/meetings_list_controller.dart';
import '../widgets/meeting_card.dart';

const _statusOptions = ['draft', 'scheduled', 'completed', 'cancelled'];

class MeetingListScreen extends ConsumerStatefulWidget {
  const MeetingListScreen({super.key});

  @override
  ConsumerState<MeetingListScreen> createState() => _MeetingListScreenState();
}

class _MeetingListScreenState extends ConsumerState<MeetingListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels > _scrollController.position.maxScrollExtent - 200) {
      ref.read(meetingsListControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(meetingsListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Meetings')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.meetingNew),
        icon: const Icon(Icons.add),
        label: const Text('New meeting'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.lg, Spacing.lg, Spacing.sm),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search meetings',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) => _applyFilters(
                state.valueOrNull?.filters ?? MeetingFilters.empty,
                search: value,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              children: [
                for (final status in _statusOptions)
                  Padding(
                    padding: const EdgeInsets.only(right: Spacing.sm),
                    child: FilterChip(
                      label: Text(status[0].toUpperCase() + status.substring(1)),
                      selected: state.valueOrNull?.filters.status == status,
                      onSelected: (selected) => _applyFilters(
                        state.valueOrNull?.filters ?? MeetingFilters.empty,
                        status: selected ? status : null,
                        clearStatus: !selected,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(error is ApiFailure ? error.message : 'Could not load meetings.'),
              ),
              data: (list) {
                if (list.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_busy,
                    title: 'No meetings yet',
                    message: 'Create your first meeting to get started.',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref.read(meetingsListControllerProvider.notifier).refresh(),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(Spacing.lg),
                    itemCount: list.items.length + (list.hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: Spacing.md),
                    itemBuilder: (context, index) {
                      if (index >= list.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: Spacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final meeting = list.items[index];
                      return MeetingCard(
                        meeting: meeting,
                        onTap: () => context.push(AppRoutes.meetingDetailsPath(meeting.id)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _applyFilters(
    MeetingFilters current, {
    String? status,
    bool clearStatus = false,
    String? search,
  }) {
    ref.read(meetingsListControllerProvider.notifier).applyFilters(
          current.copyWith(status: status, clearStatus: clearStatus, search: search),
        );
  }
}
