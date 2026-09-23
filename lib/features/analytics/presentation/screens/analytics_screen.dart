import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/workspace/presentation/providers/workspaces_list_controller.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/theme/spacing.dart';
import '../../../../core/widgets/empty_state.dart';
import '../providers/analytics_controller.dart';
import '../widgets/activity_breakdown_list.dart';
import '../widgets/analytics_stat_card.dart';
import '../widgets/meetings_per_month_chart.dart';
import '../widgets/productivity_score_gauge.dart';
import '../widgets/task_completion_chart.dart';

/// SRD FR-13.1 / PHASES.md Phase 9: Analytics Dashboard. Scoped per
/// workspace — ARCHITECTURE.md documents `GET /workspaces/{id}/analytics`,
/// not a platform-wide endpoint, so a workspace selector sits above the
/// charts (reusing Phase 7's `workspacesListControllerProvider`) rather
/// than assuming a single "current" workspace.
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  String? _selectedWorkspaceId;

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: workspaces.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.insights_outlined,
              title: 'No workspaces yet',
              message: 'Join or create a workspace to see analytics for it.',
            );
          }

          _selectedWorkspaceId ??= list.first.id;

          final selectedIndex = list.indexWhere(
                (w) => w.id == _selectedWorkspaceId,
          );

          final selected = selectedIndex >= 0
              ? list[selectedIndex]
              : list.first;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.lg,
                  Spacing.sm,
                ),
                child: DropdownButtonFormField<String>(
                  initialValue: selected.id,
                  decoration: const InputDecoration(
                    labelText: 'Workspace',
                  ),
                  items: [
                    for (final w in list)
                      DropdownMenuItem(
                        value: w.id,
                        child: Text(w.name),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedWorkspaceId = value;
                    });
                  },
                ),
              ),
              Expanded(
                child: _AnalyticsBody(
                  workspaceId: selected.id,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(analyticsControllerProvider(workspaceId));

    return analytics.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (summary) => RefreshIndicator(
        onRefresh: () => ref.read(analyticsControllerProvider(workspaceId).notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Center(child: ProductivityScoreGauge(score: summary.productivityScore)),
            const SizedBox(height: Spacing.lg),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: Spacing.md,
              crossAxisSpacing: Spacing.md,
              childAspectRatio: 2.2,
              children: [
                AnalyticsStatCard(
                  label: 'Avg. duration',
                  value: '${summary.avgMeetingDurationMinutes.round()} min',
                  icon: Icons.timer_outlined,
                ),
                AnalyticsStatCard(
                  label: 'Time spent',
                  value: '${summary.totalTimeSpentHours.toStringAsFixed(1)} hrs',
                  icon: Icons.hourglass_bottom_outlined,
                ),
                AnalyticsStatCard(
                  label: 'Active users',
                  value: '${summary.activeUserCount}',
                  icon: Icons.people_alt_outlined,
                ),
                AnalyticsStatCard(
                  label: 'Pending tasks',
                  value: '${summary.taskCompletion.pending}',
                  icon: Icons.pending_actions_outlined,
                ),
              ],
            ),


            const SizedBox(height: Spacing.xl),
            Text('Meetings per month', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            MeetingsPerMonthChart(data: summary.meetingsPerMonth),
            const SizedBox(height: Spacing.xl),
            Text('Task completion', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            TaskCompletionChart(stats: summary.taskCompletion),
            const SizedBox(height: Spacing.xl),
            Text('Department activity', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            ActivityBreakdownList(entries: summary.departmentActivity, emptyLabel: 'No departments yet.'),
            const SizedBox(height: Spacing.xl),
            Text('Top contributors', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: Spacing.md),
            ActivityBreakdownList(entries: summary.userActivity),
          ],
        ),
      ),
    );
  }
}
