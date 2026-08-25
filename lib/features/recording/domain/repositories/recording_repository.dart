import 'package:meetmind_ai/features/recording/domain/entities/recorded_audio.dart';

/// Controls the device microphone for a single in-progress recording
/// session. Implemented in data/repositories using the `record` package —
/// this abstraction keeps the presentation layer from depending on that
/// package directly (ARCHITECTURE.md 2.1).
abstract interface class RecordingRepository {
  Future<bool> hasPermission();

  /// Starts a new recording to a fresh local file. Throws
  /// [RecordingPermissionDeniedException] if permission isn't granted —
  /// callers should go through `StartRecordingUseCase`, which checks this
  /// up front rather than relying on a thrown exception for control flow.
  Future<void> start();

  Future<void> pause();

  Future<void> resume();

  /// Stops the current recording and returns the finished local file.
  Future<RecordedAudio> stop();

  /// Stops the current recording and discards the file — used when the
  /// user backs out instead of saving.
  Future<void> cancel();

  /// Normalized 0.0–1.0 input level, sampled periodically while recording,
  /// for driving a live waveform visualization.
  Stream<double> get amplitudeStream;
}
