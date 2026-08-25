

import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';
import 'package:meetmind_ai/features/recording/domain/entities/recorded_audio.dart';

/// Manages the local queue of recordings waiting to be (or being) uploaded
/// to the backend's chunked, resumable upload endpoints
/// (`POST /meetings/{id}/recording/init`, `.../chunks`, `.../status`,
/// `.../complete` — see backend AudioFileController). ARCHITECTURE.md 2.4.
abstract interface class AudioUploadRepository {
  /// Persists [audio] as a queued upload for [meetingId]. Does not upload
  /// anything itself — call [upload] (or [resumeAll]) to actually send it.
  Future<PendingUpload> enqueue({
    required String meetingId,
    required RecordedAudio audio,
  });

  /// Uploads (or resumes uploading) a single queued recording. Safe to
  /// call repeatedly, including after an app restart — it always
  /// reconciles against the server's `received_chunks` before sending
  /// anything, so it never re-sends a chunk the server already has, and
  /// never skips one it doesn't.
  Future<void> upload(String pendingUploadId);

  Future<List<PendingUpload>> listForMeeting(String meetingId);

  Future<List<PendingUpload>> listAll();

  /// Re-attempts every recording still sitting in the queue (queued,
  /// interrupted mid-upload, or previously failed). Call once at app
  /// start so a recording made just before the app was killed — or one
  /// that failed on a bad connection — doesn't get stranded.
  ///
  /// This resumes uploads for as long as the app is in the foreground; it
  /// does not (yet) use a platform background-execution API like
  /// `workmanager`, so an upload interrupted by the OS killing the app
  /// won't continue while the app is closed — it resumes the moment the
  /// app is opened again instead.
  Future<void> resumeAll();

  Future<void> remove(String pendingUploadId);
}
