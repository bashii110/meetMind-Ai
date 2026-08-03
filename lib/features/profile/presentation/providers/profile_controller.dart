import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import 'profile_providers.dart';

class ProfileController extends AsyncNotifier<AppUser> {
  @override
  Future<AppUser> build() => ref.read(getProfileUseCaseProvider)();

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
