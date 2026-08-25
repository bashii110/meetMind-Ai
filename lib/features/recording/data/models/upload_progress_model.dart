/// Maps the `{ received_chunks, total_chunks }` shape returned by
/// `GET /audio-files/{id}/status` (and `POST .../chunks`) — deliberately
/// separate from [AudioFileModel] since those endpoints don't return the
/// full AudioFileResource (no `id`/`meeting_id`/`status` fields).
class UploadProgressModel {
  const UploadProgressModel({required this.totalChunks, required this.receivedChunks});

  final int totalChunks;
  final List<int> receivedChunks;

  factory UploadProgressModel.fromJson(Map<String, dynamic> json) {
    return UploadProgressModel(
      totalChunks: json['total_chunks'] as int? ?? 0,
      receivedChunks: ((json['received_chunks'] as List?) ?? const [])
          .map((e) => e as int)
          .toList(),
    );
  }
}
