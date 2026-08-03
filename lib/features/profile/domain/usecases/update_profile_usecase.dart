import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  Future<AppUser> call({
    String? name,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
    XFile? avatar,
  }) {
    return _repository.updateProfile(
      name: name,
      bio: bio,
      company: company,
      position: position,
      timezone: timezone,
      skills: skills,
      avatar: avatar,
    );
  }
}
