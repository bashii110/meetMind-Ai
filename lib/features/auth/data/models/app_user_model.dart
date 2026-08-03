import '../../domain/entities/app_user.dart';

/// Maps the backend's UserResource JSON shape to/from the domain entity.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.emailVerified,
    required super.role,
    required super.timezone,
    super.avatar,
    super.provider,
    super.bio,
    super.company,
    super.position,
    super.skills,
  });

  factory AppUserModel.fromJson(Map<String, dynamic> json) {
    return AppUserModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      email: json['email'] as String,
      emailVerified: json['email_verified'] as bool? ?? false,
      role: json['role'] as String? ?? 'regular_user',
      timezone: json['timezone'] as String? ?? 'UTC',
      avatar: json['avatar'] as String?,
      provider: json['provider'] as String?,
      bio: json['bio'] as String?,
      company: json['company'] as String?,
      position: json['position'] as String?,
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
