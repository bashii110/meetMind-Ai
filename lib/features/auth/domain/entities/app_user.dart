import 'package:equatable/equatable.dart';

/// Pure Dart entity — no Flutter/Dio imports (ARCHITECTURE.md 2.1 domain layer).
/// Mirrors the backend's UserResource (see backend/app/Http/Resources/UserResource.php).
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.role,
    required this.timezone,
    this.avatar,
    this.provider,
    this.bio,
    this.company,
    this.position,
    this.skills = const [],
  });

  final String id;
  final String name;
  final String email;
  final bool emailVerified;
  final String role;
  final String timezone;
  final String? avatar;
  final String? provider;
  final String? bio;
  final String? company;
  final String? position;
  final List<String> skills;

  AppUser copyWith({
    String? name,
    String? avatar,
    String? bio,
    String? company,
    String? position,
    String? timezone,
    List<String>? skills,
  }) {
    return AppUser(
      id: id,
      name: name ?? this.name,
      email: email,
      emailVerified: emailVerified,
      role: role,
      timezone: timezone ?? this.timezone,
      avatar: avatar ?? this.avatar,
      provider: provider,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      position: position ?? this.position,
      skills: skills ?? this.skills,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        emailVerified,
        role,
        timezone,
        avatar,
        provider,
        bio,
        company,
        position,
        skills,
      ];
}
