import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/repositories/admin_repository.dart';
import '../../domain/usecases/get_platform_stats_usecase.dart';
import '../../domain/usecases/list_admin_users_usecase.dart';
import '../../domain/usecases/list_moderation_queue_usecase.dart';
import '../../domain/usecases/resolve_moderation_item_usecase.dart';
import '../../domain/usecases/set_user_disabled_usecase.dart';

final adminRemoteDataSourceProvider = Provider(
  (ref) => AdminRemoteDataSource(ref.watch(dioProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepositoryImpl(ref.watch(adminRemoteDataSourceProvider)),
);

final getPlatformStatsUseCaseProvider =
    Provider((ref) => GetPlatformStatsUseCase(ref.watch(adminRepositoryProvider)));
final listAdminUsersUseCaseProvider =
    Provider((ref) => ListAdminUsersUseCase(ref.watch(adminRepositoryProvider)));
final setUserDisabledUseCaseProvider =
    Provider((ref) => SetUserDisabledUseCase(ref.watch(adminRepositoryProvider)));
final listModerationQueueUseCaseProvider =
    Provider((ref) => ListModerationQueueUseCase(ref.watch(adminRepositoryProvider)));
final resolveModerationItemUseCaseProvider =
    Provider((ref) => ResolveModerationItemUseCase(ref.watch(adminRepositoryProvider)));
