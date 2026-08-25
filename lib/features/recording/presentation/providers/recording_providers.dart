import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meetmind_ai/features/recording/data/datasources/audio_recorder_data_source.dart';
import 'package:meetmind_ai/features/recording/data/repositories/recording_repository_impl.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/recording_repository.dart';
import 'package:meetmind_ai/features/recording/data/datasources/audio_upload_remote_data_source.dart';
import 'package:meetmind_ai/features/recording/data/datasources/pending_upload_local_data_source.dart';
import 'package:meetmind_ai/features/recording/data/repositories/audio_upload_repository_impl.dart';
import 'package:meetmind_ai/features/recording/domain/repositories/audio_upload_repository.dart';
import 'package:meetmind_ai/features/recording/domain/usecases/retry_upload_usecase.dart';
import 'package:meetmind_ai/features/recording/domain/usecases/start_recording_usecase.dart';
import 'package:meetmind_ai/features/recording/domain/usecases/stop_recording_usecase.dart';

import '../../../../../../core/di/providers.dart';

final audioRecorderDataSourceProvider = Provider((ref) => AudioRecorderDataSource());

final recordingRepositoryProvider = Provider<RecordingRepository>(
  (ref) => RecordingRepositoryImpl(ref.watch(audioRecorderDataSourceProvider)),
);

final audioUploadRemoteDataSourceProvider = Provider(
  (ref) => AudioUploadRemoteDataSource(ref.watch(dioProvider)),
);

final pendingUploadLocalDataSourceProvider = Provider((ref) => PendingUploadLocalDataSource());

final audioUploadRepositoryProvider = Provider<AudioUploadRepository>(
  (ref) => AudioUploadRepositoryImpl(
    remote: ref.watch(audioUploadRemoteDataSourceProvider),
    local: ref.watch(pendingUploadLocalDataSourceProvider),
  ),
);

final startRecordingUseCaseProvider =
    Provider((ref) => StartRecordingUseCase(ref.watch(recordingRepositoryProvider)));

final stopRecordingUseCaseProvider = Provider(
  (ref) => StopRecordingUseCase(
    recordingRepository: ref.watch(recordingRepositoryProvider),
    uploadRepository: ref.watch(audioUploadRepositoryProvider),
  ),
);

final retryUploadUseCaseProvider =
    Provider((ref) => RetryUploadUseCase(ref.watch(audioUploadRepositoryProvider)));
