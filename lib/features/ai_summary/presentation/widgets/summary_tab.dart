import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai%20status/presentation/providers/ai_status_controller.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';
import 'package:meetmind_ai/features/meetings/presentation/providers/meeting_summary_provider.dart';

import '../../../../../../core/network/api_failure.dart';
import '../../../../../../core/theme/spacing.dart';
import '../../../ai status/presentation/screens/ai_status_states.dart';

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key, required this.meetingId});

  final String meetingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusControllerProvider(meetingId));

    return status.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
      data: (aiStatus) {
        if (!aiStatus.hasRecording) {
          return const AiEmptyState(
            icon: Icons.auto_awesome,
            title: 'No summary yet',
            message: 'Record this meeting and an AI-generated summary will appear here automatically.',
          );
        }
        if (aiStatus.hasFailed) {
          return AiFailedState(message: aiStatus.errorMessage ?? 'Processing failed.');
        }
        // The summary only exists once status reaches summarized —
        // GenerateSummaryJob writes it before that.
        if (aiStatus.status != AiPipelineStatus.summarized) {
          return AiProcessingState(label: aiStatus.label);
        }

        final summary = ref.watch(meetingSummaryProvider(meetingId));
        return summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
          data: (s) {
            if (s == null) return AiProcessingState(label: aiStatus.label);
            return _SummaryContent(summary: s);
          },
        );
      },
    );
  }
}

class _SummaryContent extends StatelessWidget {
  const _SummaryContent({required this.summary});

  final MeetingSummary summary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome, size: 18, color: scheme.tertiary),
            const SizedBox(width: Spacing.xs),
            Text(
              'AI-generated summary',
              style: TextStyle(color: scheme.tertiary, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _MoodBadge(mood: summary.mood),
          ],
        ),
        const SizedBox(height: Spacing.lg),
        Card(
          color: scheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Text(summary.executiveSummary),
          ),
        ),
        const SizedBox(height: Spacing.md),
        _SummarySection(title: 'Key points', icon: Icons.list_alt, items: summary.bulletSummary),
        _SummarySection(title: 'Decisions', icon: Icons.check_circle_outline, items: summary.decisions),
        _SummarySection(title: 'Risks', icon: Icons.warning_amber_outlined, items: summary.risks),
        _SummarySection(title: 'Next steps', icon: Icons.arrow_forward, items: summary.nextSteps),
        _SummarySection(title: 'Deadlines', icon: Icons.event_outlined, items: summary.deadlines),
      ],
    );
  }
}

/// Collapsible per DESIGN.md 3.6. Hides itself entirely when the AI
/// returned no items for this section, rather than showing an empty card.
class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.icon, required this.items});

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        initiallyExpanded: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBadge extends StatelessWidget {
  const _MoodBadge({required this.mood});

  final MeetingMood mood;

  @override
  Widget build(BuildContext context) {
    final (emoji, label, color) = switch (mood) {
      MeetingMood.positive => ('🙂', 'Positive', Colors.green),
      MeetingMood.neutral => ('😐', 'Neutral', Colors.grey),
      MeetingMood.tense => ('😟', 'Tense', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$emoji $label',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
