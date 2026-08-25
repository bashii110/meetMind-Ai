/// Maps the backend's `AudioFileResource` JSON shape, returned by
/// `POST /meetings/{id}/recording/init` and `POST /audio-files/{id}/complete`.
class AudioFileModel {
  const AudioFileModel({
    required this.id,
    required this.meetingId,
    required this.status,
    required this.totalChunks,
    required this.receivedChunks,
  });

  final String id;
  final String meetingId;
  final String status;
  final int totalChunks;
  final List<int> receivedChunks;

  factory AudioFileModel.fromJson(Map<String, dynamic> json) {
    return AudioFileModel(
      id: json['id'].toString(),
      meetingId: json['meeting_id'].toString(),
      status: json['status'] as String? ?? 'pending',
      totalChunks: json['total_chunks'] as int? ?? 0,
      receivedChunks: ((json['received_chunks'] as List?) ?? const [])
          .map((e) => e as int)
          .toList(),
    );
  }
}
