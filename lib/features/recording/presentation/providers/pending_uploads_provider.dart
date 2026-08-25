import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';
import 'recording_providers.dart';

/// Read-only view of a meeting's pending/uploading/failed recordings, for
/// the meeting details screen's background-upload banner. autoDispose
/// since it's cheap to recompute (a Hive read) and there's no reason to
/// keep it cached once the screen isn't showing it.
final pendingUploadsForMeetingProvider =
    FutureProvider.autoDispose.family<List<PendingUpload>, String>((ref, meetingId) {
  return ref.watch(audioUploadRepositoryProvider).listForMeeting(meetingId);
});
