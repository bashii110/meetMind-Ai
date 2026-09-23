import 'package:meetmind_ai/features/auth/domain/entities/app_user.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';

/// Overrides [AuthController.build] to resolve to a fixed user (or null)
/// synchronously, so tests for controllers that depend on
/// `authControllerProvider` (e.g. MeetingsListController) don't need a
/// real token/network round trip.
class FixedAuthController extends AuthController {
  FixedAuthController(this._user);

  final AppUser? _user;

  @override
  Future<AppUser?> build() async => _user;
}
