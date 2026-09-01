import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/core/di/providers.dart';
import 'package:meetmind_ai/features/ai%20status/domain/usecases/get_ai_status_usecase.dart';
import 'package:meetmind_ai/features/ai_summary/data/datasources/ai_summary_remote_data_source.dart';
import 'package:meetmind_ai/features/ai_summary/data/repositories/ai_summary_repository_impl.dart';
import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:meetmind_ai/features/ai_summary/domain/usecases/query_assistant_usecase.dart';
import 'package:meetmind_ai/features/meetings/domain/usecases/get_meeting_summary_usecase.dart';
import 'package:meetmind_ai/features/tasks/domain/usecases/confirm_task_candidate_usecase.dart';
import 'package:meetmind_ai/features/tasks/domain/usecases/dismiss_task_candidate_usecase.dart';
import 'package:meetmind_ai/features/tasks/domain/usecases/list_task_candidates_usecase.dart';
import 'package:meetmind_ai/features/transcript/domain/usecases/get_transcript_usecase.dart';


final aiSummaryRemoteDataSourceProvider = Provider(
  (ref) => AiSummaryRemoteDataSource(ref.watch(dioProvider)),
);

final aiSummaryRepositoryProvider = Provider<AiSummaryRepository>(
  (ref) => AiSummaryRepositoryImpl(ref.watch(aiSummaryRemoteDataSourceProvider)),
);

final getAiStatusUseCaseProvider = Provider((ref) => GetAiStatusUseCase(ref.watch(aiSummaryRepositoryProvider)));
final getTranscriptUseCaseProvider =
    Provider((ref) => GetTranscriptUseCase(ref.watch(aiSummaryRepositoryProvider)));
final getMeetingSummaryUseCaseProvider =
    Provider((ref) => GetMeetingSummaryUseCase(ref.watch(aiSummaryRepositoryProvider)));
final listTaskCandidatesUseCaseProvider =
    Provider((ref) => ListTaskCandidatesUseCase(ref.watch(aiSummaryRepositoryProvider)));
final confirmTaskCandidateUseCaseProvider =
    Provider((ref) => ConfirmTaskCandidateUseCase(ref.watch(aiSummaryRepositoryProvider)));
final dismissTaskCandidateUseCaseProvider =
    Provider((ref) => DismissTaskCandidateUseCase(ref.watch(aiSummaryRepositoryProvider)));
// Phase 8: AI Chat Assistant (SRD FR-11.x).
final queryAssistantUseCaseProvider =
    Provider((ref) => QueryAssistantUseCase(ref.watch(aiSummaryRepositoryProvider)));
