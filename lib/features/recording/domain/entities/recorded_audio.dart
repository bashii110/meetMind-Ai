/// The result of stopping a recording session — a local file on disk that
/// hasn't been queued for upload yet. See [PendingUpload] for the queued,
/// persisted form.
class RecordedAudio {
  const RecordedAudio({
    required this.filePath,
    required this.extension,
    required this.duration,
    required this.fileSizeBytes,
  });

  final String filePath;
  final String extension;
  final Duration duration;
  final int fileSizeBytes;
}
