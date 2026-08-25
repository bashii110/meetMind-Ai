import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';


/// Thin wrapper around `package:record`'s [AudioRecorder]. Also tracks
/// elapsed recording duration itself (summing segments across
/// pause/resume) rather than relying on a UI-side timer, so the duration
/// reported to the backend on `stop()` is accurate regardless of how the
/// widget tree ticks.
class AudioRecorderDataSource {
  AudioRecorderDataSource({AudioRecorder? recorder}) : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;

  DateTime? _segmentStartedAt;
  Duration _accumulated = Duration.zero;

  Duration get elapsed {
    if (_segmentStartedAt == null) return _accumulated;
    return _accumulated + DateTime.now().difference(_segmentStartedAt!);
  }

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<String> start() async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1, // voice, not music — halves the file size vs. stereo
      ),
      path: path,
    );

    _accumulated = Duration.zero;
    _segmentStartedAt = DateTime.now();
    return path;
  }

  Future<void> pause() async {
    await _recorder.pause();
    _closeCurrentSegment();
  }

  Future<void> resume() async {
    await _recorder.resume();
    _segmentStartedAt = DateTime.now();
  }

  Future<String?> stop() async {
    final path = await _recorder.stop();
    _closeCurrentSegment();
    return path;
  }

  /// Stops and discards the recording — [AudioRecorder.cancel] already
  /// deletes the underlying file/blob itself.
  Future<void> cancel() async {
    await _recorder.cancel();
    _segmentStartedAt = null;
    _accumulated = Duration.zero;
  }

  /// Normalized 0.0–1.0 input level. `Amplitude.current` is a dBFS value
  /// (roughly -60 silence to 0 peak on typical mobile mics); this maps
  /// that range onto 0..1 for a simple bar-style waveform visualization —
  /// it's an approximation, not a calibrated loudness meter.
  Stream<double> get amplitudeStream => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 200))
      .map((amp) => ((amp.current + 60) / 60).clamp(0.0, 1.0));

  Future<void> dispose() => _recorder.dispose();

  void _closeCurrentSegment() {
    if (_segmentStartedAt != null) {
      _accumulated += DateTime.now().difference(_segmentStartedAt!);
      _segmentStartedAt = null;
    }
  }
}
