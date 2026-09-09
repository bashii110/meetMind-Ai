import '../../domain/entities/admin_user.dart';
import '../../domain/entities/moderation_item.dart';
import '../../domain/entities/platform_stats.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_data_source.dart';

class AdminRepositoryImpl implements AdminRepository {
  const AdminRepositoryImpl(this._remote);

  final AdminRemoteDataSource _remote;

  @override
  Future<PlatformStats> getPlatformStats() => _remote.getPlatformStats();

  @override
  Future<PaginatedAdminUsers> listUsers({String? search, int page = 1}) {
    return _remote.listUsers({
      if (search != null && search.isNotEmpty) 'search': search,
    }, page);
  }

  @override
  Future<AdminUser> setUserDisabled(String userId, bool disabled) => _remote.setUserDisabled(userId, disabled);

  @override
  Future<PaginatedModerationItems> listModerationQueue({int page = 1}) => _remote.listModerationQueue(page);

  @override
  Future<void> resolveModerationItem(String itemId, {required bool remove}) {
    return _remote.resolveModerationItem(itemId, remove);
  }
}
