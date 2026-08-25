import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meetmind_ai/features/auth/domain/entities/app_user.dart';
import 'package:meetmind_ai/features/auth/presentation/providers/auth_controller.dart';
import 'package:meetmind_ai/features/profile/presentation/providers/profile_providers.dart';

class ProfileController extends AsyncNotifier<AppUser> {
  @override
  Future<AppUser> build() {
    // Rebuild whenever the signed-in user changes (login, logout, or a
    // different account logging in afterwards). This provider is
    // intentionally NOT autoDispose (so profile data stays cached while
    // navigating), which means without this dependency it would keep
    // serving the *previous* user's cached profile after a logout/login
    // switch, until something happened to force a refetch.
    ref.watch(authControllerProvider.select((state) => state.valueOrNull?.id));
    return ref.read(getProfileUseCaseProvider)();
  }

  Future<void> updateProfile({
    String? name,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
    XFile? avatar,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() {
      return ref.read(updateProfileUseCaseProvider)(
        name: name,
        bio: bio,
        company: company,
        position: position,
        timezone: timezone,
        skills: skills,
        avatar: avatar,
      );
    });

    final updated = state.valueOrNull;
    if (updated != null) {
      // Keep the dashboard's/app-wide cached user (from AuthController) in
      // sync so a name/avatar change shows up immediately without a
      // separate /auth/me round trip.
      ref.read(authControllerProvider.notifier).setUser(updated);
    } else if (state.hasError) {
      throw state.error!;
    }
  }
}

final profileControllerProvider = AsyncNotifierProvider<ProfileController, AppUser>(ProfileController.new);
