import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai%20status/presentation/providers/ai_status_controller.dart';
import 'package:meetmind_ai/features/transcript/presentation/providers/transcript_provider.dart';

import '../../../../../../core/network/api_failure.dart';
import '../../../../../../core/theme/spacing.dart';
import '../../../ai status/presentation/screens/ai_status_states.dart';

class TranscriptTab extends ConsumerWidget {
  const TranscriptTab({super.key, required this.meetingId});

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
            icon: Icons.mic_none_rounded,
            title: 'No recording yet',
            message: 'Record this meeting and a transcript will appear here automatically.',
          );
        }
        if (aiStatus.hasFailed) {
          return AiFailedState(message: aiStatus.errorMessage ?? 'Processing failed.');
        }
        // The transcript exists once status has moved past transcribing —
        // TranscribeAudioJob writes it before advancing the status.
        final transcriptExpected = aiStatus.status != AiPipelineStatus.pending &&
            aiStatus.status != AiPipelineStatus.uploading &&
            aiStatus.status != AiPipelineStatus.uploaded &&
            aiStatus.status != AiPipelineStatus.transcribing;
        if (!transcriptExpected) {
          return AiProcessingState(label: aiStatus.label);
        }

        final transcript = ref.watch(transcriptProvider(meetingId));
        return transcript.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text(ApiFailure.from(error).message)),
          data: (t) {
            if (t == null) return AiProcessingState(label: aiStatus.label);
            return SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.lg),
              child: SelectableText(
                t.text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
              ),
            );
          },
        );
      },
    );
  }
}
