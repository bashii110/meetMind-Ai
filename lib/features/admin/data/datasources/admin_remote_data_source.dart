import 'package:dio/dio.dart';

import '../models/admin_user_model.dart';
import '../models/moderation_item_model.dart';
import '../models/platform_stats_model.dart';

/// Talks to /admin/* — platform-wide administration (SRD FR-16.x), gated
/// server-side to system admins (Policy-enforced, per ARCHITECTURE.md
/// section 6) regardless of what the client shows or hides.
class AdminRemoteDataSource {
  const AdminRemoteDataSource(this._dio);

  final Dio _dio;

  Future<PlatformStatsModel> getPlatformStats() async {
    final response = await _dio.get('/admin/stats');
    return PlatformStatsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedAdminUsersModel> listUsers(Map<String, dynamic> queryParameters, int page) async {
    final response = await _dio.get('/admin/users', queryParameters: {
      ...queryParameters,
      'page': page,
    });
    return PaginatedAdminUsersModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<AdminUserModel> setUserDisabled(String userId, bool disabled) async {
    final response = await _dio.patch('/admin/users/$userId/disable', data: {'disabled': disabled});
    return AdminUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<PaginatedModerationItemsModel> listModerationQueue(int page) async {
    final response = await _dio.get('/admin/moderation', queryParameters: {'page': page});
    return PaginatedModerationItemsModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  Future<void> resolveModerationItem(String itemId, bool remove) {
    return _dio.post('/admin/moderation/$itemId/resolve', data: {'action': remove ? 'remove' : 'dismiss'});
  }
}
