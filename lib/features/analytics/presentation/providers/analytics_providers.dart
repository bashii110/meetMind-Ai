import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/analytics_remote_data_source.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/usecases/get_workspace_analytics_usecase.dart';

final analyticsRemoteDataSourceProvider = Provider(
  (ref) => AnalyticsRemoteDataSource(ref.watch(dioProvider)),
);

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => AnalyticsRepositoryImpl(ref.watch(analyticsRemoteDataSourceProvider)),
);

final getWorkspaceAnalyticsUseCaseProvider =
    Provider((ref) => GetWorkspaceAnalyticsUseCase(ref.watch(analyticsRepositoryProvider)));
