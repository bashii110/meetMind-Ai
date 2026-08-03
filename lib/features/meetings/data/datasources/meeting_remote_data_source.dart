import 'package:dio/dio.dart';

import '../models/meeting_model.dart';
import '../models/paginated_meetings_model.dart';

class MeetingRemoteDataSource {
  const MeetingRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PaginatedMeetingsModel> list(Map<String, dynamic> queryParameters, int page) async {
    final response = await _dio.get('/meetings', queryParameters: {
      ...queryParameters,
      'page': page,
    });
    return PaginatedMeetingsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MeetingModel> getById(String id) async {
    final response = await _dio.get('/meetings/$id');
    return MeetingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MeetingModel> create(Map<String, dynamic> body) async {
    final response = await _dio.post('/meetings', data: body);
    return MeetingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<MeetingModel> update(String id, Map<String, dynamic> body) async {
    final response = await _dio.put('/meetings/$id', data: body);
    return MeetingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/meetings/$id');

  Future<MeetingModel> changeStatus(String id, String status) async {
    final response = await _dio.patch('/meetings/$id/status', data: {'status': status});
    return MeetingModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// @return the emails that didn't match a registered user
  Future<List<String>> inviteParticipants(String meetingId, List<String> emails) async {
    final response = await _dio.post('/meetings/$meetingId/participants', data: {'emails': emails});
    final notFound = response.data['data']['not_found_emails'] as List? ?? const [];
    return notFound.map((e) => e.toString()).toList();
  }

  Future<void> removeParticipant(String meetingId, String userId) {
    return _dio.delete('/meetings/$meetingId/participants/$userId');
  }

  Future<void> respondToInvitation(String meetingId, String status) {
    return _dio.post('/meetings/$meetingId/participants/respond', data: {'status': status});
  }
}
