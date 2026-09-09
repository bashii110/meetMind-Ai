import '../entities/admin_user.dart';
import '../entities/moderation_item.dart';
import '../entities/platform_stats.dart';

/// Implemented by data/repositories/admin_repository_impl.dart. Use cases
/// and the presentation layer depend on this abstraction, never the impl
/// directly (ARCHITECTURE.md 2.1).
abstract interface class AdminRepository {
  Future<PlatformStats> getPlatformStats();

  Future<PaginatedAdminUsers> listUsers({String? search, int page = 1});

  /// Toggles whether [userId] can sign in — SRD FR-16.1.
  Future<AdminUser> setUserDisabled(String userId, bool disabled);

  Future<PaginatedModerationItems> listModerationQueue({int page = 1});

  /// [remove] true deletes the reported content; false dismisses the
  /// report without action.
  Future<void> resolveModerationItem(String itemId, {required bool remove});
}
