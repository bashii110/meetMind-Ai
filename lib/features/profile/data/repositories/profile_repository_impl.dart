import 'package:image_picker/image_picker.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remote);

  final ProfileRemoteDataSource _remote;

  @override
  Future<AppUser> getProfile() => _remote.getProfile();

  @override
  Future<AppUser> updateProfile({
    String? name,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
    XFile? avatar,
  }) {
    return _remote.updateProfile(
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
