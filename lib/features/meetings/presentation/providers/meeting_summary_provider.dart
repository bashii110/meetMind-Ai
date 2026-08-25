import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';

import '../../../ai_summary/presentation/providers/ai_summary_providers.dart';

/// autoDispose — cheap to refetch, no reason to keep cached once the
/// Summary tab isn't visible. Returns null while the summary hasn't been
/// generated yet (see AiSummaryRepository.getSummary); the Summary tab
/// only watches this once ai-status says it should exist.
final meetingSummaryProvider = FutureProvider.autoDispose.family<MeetingSummary?, String>((ref, meetingId) {
  return ref.watch(getMeetingSummaryUseCaseProvider)(meetingId);
});
