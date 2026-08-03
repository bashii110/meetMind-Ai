import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../auth/data/models/app_user_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AppUserModel> getProfile() async {
    final response = await _dio.get('/profile');
    return AppUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Always sent as multipart/form-data (even without [avatar]) so array
  /// fields like `skills[]` and an optional file upload share one code
  /// path — see backend/app/Http/Requests/Profile/UpdateProfileRequest.php.
  Future<AppUserModel> updateProfile({
    String? name,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
    XFile? avatar,
  }) async {
    final form = FormData();

    if (name != null) form.fields.add(MapEntry('name', name));
    if (bio != null) form.fields.add(MapEntry('bio', bio));
    if (company != null) form.fields.add(MapEntry('company', company));
    if (position != null) form.fields.add(MapEntry('position', position));
    if (timezone != null) form.fields.add(MapEntry('timezone', timezone));
    if (skills != null) {
      for (final skill in skills) {
        form.fields.add(MapEntry('skills[]', skill));
      }
    }
    if (avatar != null) {
      form.files.add(MapEntry(
        'avatar',
        await MultipartFile.fromFile(avatar.path, filename: avatar.name),
      ));
    }

    final response = await _dio.post('/profile', data: form);
    return AppUserModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
