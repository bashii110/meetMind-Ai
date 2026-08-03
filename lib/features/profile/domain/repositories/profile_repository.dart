import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/app_user.dart';

/// Profile is a view onto the same User resource auth manages, so it
/// reuses [AppUser] rather than duplicating an entity (see
/// frontend/README.md's Architecture section for this convention).
abstract interface class ProfileRepository {
  Future<AppUser> getProfile();

  Future<AppUser> updateProfile({
    String? name,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
    XFile? avatar,
  });
}
