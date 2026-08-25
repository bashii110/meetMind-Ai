import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';
import '../../../ai_summary/presentation/providers/ai_summary_providers.dart';

/// autoDispose — the review queue only matters while the Tasks tab is
/// open; there's no reason to keep it cached in the background the way
/// e.g. the meetings list is.
class TaskCandidatesController extends AutoDisposeFamilyAsyncNotifier<List<TaskCandidate>, String> {
  @override
  Future<List<TaskCandidate>> build(String meetingId) {
    return ref.read(listTaskCandidatesUseCaseProvider)(meetingId);
  }

  /// FR-6.3: confirm a suggestion (optionally edited first) into a real
  /// Task. Refetches the list afterward rather than optimistically
  /// removing the item locally, so the review queue always reflects what
  /// the server actually has — consistent with how the rest of this app
  /// handles mutations (e.g. MeetingsListController.refresh()).
  Future<void> confirm(
    String taskCandidateId, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? assignedUserId,
  }) async {
    await ref.read(confirmTaskCandidateUseCaseProvider)(
      taskCandidateId,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
      assignedUserId: assignedUserId,
    );
    await _refresh();
  }

  Future<void> dismiss(String taskCandidateId) async {
    await ref.read(dismissTaskCandidateUseCaseProvider)(taskCandidateId);
    await _refresh();
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(listTaskCandidatesUseCaseProvider)(arg));
  }
}

final taskCandidatesControllerProvider = AsyncNotifierProvider.autoDispose
    .family<TaskCandidatesController, List<TaskCandidate>, String>(TaskCandidatesController.new);
