import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/recording/domain/entities/pending_upload.dart';

import '../../../../../../core/network/api_failure.dart';
import 'recording_providers.dart';

enum RecordingPhase { idle, recording, paused, stopping }

class RecordingState {
  const RecordingState({
    this.phase = RecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.amplitude = 0,
    this.errorMessage,
  });

  final RecordingPhase phase;
  final Duration elapsed;

  /// Normalized 0.0–1.0 input level, for the waveform widget.
  final double amplitude;
  final String? errorMessage;

  RecordingState copyWith({
    RecordingPhase? phase,
    Duration? elapsed,
    double? amplitude,
    String? errorMessage,
  }) {
    return RecordingState(
      phase: phase ?? this.phase,
      elapsed: elapsed ?? this.elapsed,
      amplitude: amplitude ?? this.amplitude,
      // Deliberately not `?? this.errorMessage` — callers pass null to
      // explicitly clear a previous error on the next attempt.
      errorMessage: errorMessage,
    );
  }
}

/// autoDispose: a recording session only matters while the record screen
/// is open. Once stopped, the resulting upload lives on independently in
/// [AudioUploadRepository]/Hive — this controller's job ends at "stop".
class RecordingController extends AutoDisposeNotifier<RecordingState> {
  Timer? _ticker;
  StreamSubscription<double>? _amplitudeSub;

  @override
  RecordingState build() {
    ref.onDispose(() {
      _ticker?.cancel();
      _amplitudeSub?.cancel();
    });
    return const RecordingState();
  }

  Future<void> start() async {
    try {
      await ref.read(startRecordingUseCaseProvider)();
      state = const RecordingState(phase: RecordingPhase.recording);
      _startTicker();
      _listenAmplitude();
    } catch (e) {
      state = state.copyWith(errorMessage: ApiFailure.from(e).message);
    }
  }

  Future<void> pause() async {
    await ref.read(recordingRepositoryProvider).pause();
    _ticker?.cancel();
    state = state.copyWith(phase: RecordingPhase.paused);
  }

  Future<void> resume() async {
    await ref.read(recordingRepositoryProvider).resume();
    _startTicker();
    state = state.copyWith(phase: RecordingPhase.recording);
  }

  /// Stops recording, queues the file for upload, and returns once it's
  /// safely queued — the upload itself continues in the background
  /// (DESIGN.md 3.5), so this doesn't wait for it to finish.
  Future<PendingUpload?> stopAndUpload(String meetingId) async {
    _ticker?.cancel();
    await _amplitudeSub?.cancel();
    state = state.copyWith(phase: RecordingPhase.stopping);

    try {
      final pending = await ref.read(stopRecordingUseCaseProvider)(meetingId: meetingId);
      state = const RecordingState();
      return pending;
    } catch (e) {
      state = state.copyWith(phase: RecordingPhase.idle, errorMessage: ApiFailure.from(e).message);
      return null;
    }
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    await _amplitudeSub?.cancel();
    await ref.read(recordingRepositoryProvider).cancel();
    state = const RecordingState();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
    });
  }

  void _listenAmplitude() {
    _amplitudeSub?.cancel();
    _amplitudeSub = ref.read(recordingRepositoryProvider).amplitudeStream.listen((value) {
      state = state.copyWith(amplitude: value);
    });
  }
}

final recordingControllerProvider =
    AutoDisposeNotifierProvider<RecordingController, RecordingState>(RecordingController.new);
