import 'package:dio/dio.dart';
import 'package:meetmind_ai/features/ai%20status/data/models/ai_status_model.dart';
import 'package:meetmind_ai/features/meetings/data/models/meeting_summary_model.dart';
import 'package:meetmind_ai/features/tasks/data/models/task_candidate_model.dart';
import 'package:meetmind_ai/features/transcript/data/models/transcript_model.dart';


/// Talks to MeetingAiController + TaskCandidateController — see
/// backend/routes/api.php. `getTranscript`/`getSummary` let a 404
/// ("not available yet") propagate as a normal DioException; the
/// repository is what translates that into a null return, since "not
/// ready yet" is domain-meaningful, not a data-layer concern.
class AiSummaryRemoteDataSource {
  const AiSummaryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AiStatusModel> getStatus(String meetingId) async {
    final response = await _dio.get('/meetings/$meetingId/ai-status');
    return AiStatusModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<TranscriptModel> getTranscript(String meetingId) async {
    final response = await _dio.get('/meetings/$meetingId/transcript');
    return TranscriptModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MeetingSummaryModel> getSummary(String meetingId) async {
    final response = await _dio.get('/meetings/$meetingId/summary');
    return MeetingSummaryModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<List<TaskCandidateModel>> getTaskCandidates(String meetingId) async {
    final response = await _dio.get('/meetings/$meetingId/task-candidates');
    final list = response.data['data'] as List;
    return list.map((e) => TaskCandidateModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> confirmTaskCandidate(String taskCandidateId, Map<String, dynamic> overrides) {
    return _dio.post('/task-candidates/$taskCandidateId/confirm', data: overrides);
  }

  Future<void> dismissTaskCandidate(String taskCandidateId) {
    return _dio.post('/task-candidates/$taskCandidateId/dismiss');
  }
}
