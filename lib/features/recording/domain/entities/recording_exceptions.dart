/// Thrown by [RecordingRepository.start] (via `StartRecordingUseCase`) when
/// the microphone permission wasn't granted. Kept as a distinct type
/// (rather than a raw String) so the UI layer can show a specific,
/// actionable message instead of a generic failure.
class RecordingPermissionDeniedException implements Exception {
  const RecordingPermissionDeniedException();

  @override
  String toString() =>
      'Microphone access is required to record a meeting. Please allow it in your device settings.';
}
