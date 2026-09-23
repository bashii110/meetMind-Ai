import 'package:flutter_test/flutter_test.dart';
import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';

void main() {
  test('round-trips through toJson/fromJson', () {
    final upload = PendingUpload(
      id: 'p1',
      meetingId: 'm1',
      filePath: '/tmp/rec.m4a',
      extension: 'm4a',
      totalChunks: 4,
      fileSizeBytes: 2048,
      durationSeconds: 90,
      createdAt: DateTime.utc(2026, 1, 1),
      remoteAudioFileId: 'af1',
      uploadedChunks: const [0, 1],
      status: PendingUploadStatus.uploading,
    );

    final restored = PendingUpload.fromJson(upload.toJson());

    expect(restored.id, 'p1');
    expect(restored.remoteAudioFileId, 'af1');
    expect(restored.uploadedChunks, [0, 1]);
    expect(restored.status, PendingUploadStatus.uploading);
  });

  test('progress is 0 when there are no chunks yet', () {
    final upload = PendingUpload(
      id: 'p2',
      meetingId: 'm1',
      filePath: '/tmp/rec.m4a',
      extension: 'm4a',
      totalChunks: 0,
      fileSizeBytes: 0,
      durationSeconds: 0,
      createdAt: DateTime.utc(2026, 1, 1),
    );

    expect(upload.progress, 0);
  });

  test('progress reflects the uploaded-chunk ratio', () {
    final upload = PendingUpload(
      id: 'p3',
      meetingId: 'm1',
      filePath: '/tmp/rec.m4a',
      extension: 'm4a',
      totalChunks: 4,
      fileSizeBytes: 4096,
      durationSeconds: 30,
      createdAt: DateTime.utc(2026, 1, 1),
      uploadedChunks: const [0, 1],
    );

    expect(upload.progress, 0.5);
  });

  test('copyWith clears errorMessage when not re-passed (retry convention)', () {
    final upload = PendingUpload(
      id: 'p4',
      meetingId: 'm1',
      filePath: '/tmp/rec.m4a',
      extension: 'm4a',
      totalChunks: 1,
      fileSizeBytes: 100,
      durationSeconds: 5,
      createdAt: DateTime.utc(2026, 1, 1),
      status: PendingUploadStatus.failed,
      errorMessage: 'timed out',
    );

    final retried = upload.copyWith(status: PendingUploadStatus.uploading);

    expect(retried.errorMessage, isNull);
    expect(retried.status, PendingUploadStatus.uploading);
  });
}
