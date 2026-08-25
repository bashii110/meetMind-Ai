import 'dart:io';

import 'package:meetmind_ai/features/recording/data/datasources/audio_recorder_data_source.dart';
import 'package:meetmind_ai/features/recording/domain/entities/recorded_audio.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/recording_repository.dart';



class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl(this._recorder);

  final AudioRecorderDataSource _recorder;

  @override
  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    await _recorder.start();
  }

  @override
  Future<void> pause() => _recorder.pause();

  @override
  Future<void> resume() => _recorder.resume();

  @override
  Future<RecordedAudio> stop() async {
    final path = await _recorder.stop();
    if (path == null) {
      throw StateError('Recording stopped but no audio file was produced.');
    }
    final duration = _recorder.elapsed;
    final file = File(path);
    final size = await file.length();
    return RecordedAudio(
      filePath: path,
      extension: 'm4a',
      duration: duration,
      fileSizeBytes: size,
    );
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Stream<double> get amplitudeStream => _recorder.amplitudeStream;
}
