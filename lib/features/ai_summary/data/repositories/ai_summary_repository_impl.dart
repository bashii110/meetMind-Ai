import 'package:dio/dio.dart';
import 'package:meetmind_ai/features/ai%20status/domain/entities/ai_status.dart';
import 'package:meetmind_ai/features/ai_summary/data/datasources/ai_summary_remote_data_source.dart';
import 'package:meetmind_ai/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:meetmind_ai/features/meetings/domain/entities/meeting_summary.dart';
import 'package:meetmind_ai/features/tasks/domain/entities/task_candidate.dart';
import 'package:meetmind_ai/features/transcript/domain/entities/transcript.dart';

class AiSummaryRepositoryImpl implements AiSummaryRepository {
  const AiSummaryRepositoryImpl(this._remote);

  final AiSummaryRemoteDataSource _remote;

  @override
  Future<AiStatus> getStatus(String meetingId) => _remote.getStatus(meetingId);

  @override
  Future<Transcript?> getTranscript(String meetingId) async {
    try {
      return await _remote.getTranscript(meetingId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<MeetingSummary?> getSummary(String meetingId) async {
    try {
      return await _remote.getSummary(meetingId);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<TaskCandidate>> getTaskCandidates(String meetingId) => _remote.getTaskCandidates(meetingId);

  @override
  Future<void> confirmTaskCandidate(
    String taskCandidateId, {
    String? title,
    String? description,
    String? priority,
    DateTime? deadline,
    String? assignedUserId,
  }) {
    return _remote.confirmTaskCandidate(taskCandidateId, {
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priority != null) 'priority': priority,
      if (deadline != null) 'deadline': _formatDate(deadline),
      if (assignedUserId != null) 'assigned_user_id': int.tryParse(assignedUserId) ?? assignedUserId,
    });
  }

  @override
  Future<void> dismissTaskCandidate(String taskCandidateId) => _remote.dismissTaskCandidate(taskCandidateId);

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
