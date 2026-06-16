import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/auth/domain/entities/user.dart';

class UserProfileModel {
  const UserProfileModel({
    required this.id,
    required this.displayName,
    required this.isPublic,
    required this.createdAt,
    this.email,
    this.photoUrl,
    this.bio,
    this.city,
    this.position,
    this.skillLevel,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) =>
      UserProfileModel(
        id: json['id'] as String,
        displayName: (json['displayName'] as String?) ?? '',
        isPublic: json['isPublic'] as bool? ?? true,
        createdAt: json['createdAt'] as String,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        bio: json['bio'] as String?,
        city: json['city'] as String?,
        position: json['position'] as String?,
        skillLevel: json['skillLevel'] as int?,
      );

  final String id;
  final String? email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final String? city;
  final String? position;
  final int? skillLevel;
  final bool isPublic;
  final String createdAt;

  PlayerProfile toEntity() {
    final ts = DateTime.parse(createdAt);
    return PlayerProfile(
      userId: id,
      displayName: displayName,
      photoUrl: photoUrl,
      bio: bio,
      city: city,
      position: _parsePosition(position),
      skillLevel: _parseSkillLevel(skillLevel),
      isPublic: isPublic,
      createdAt: ts,
      updatedAt: ts,
    );
  }

  static PlayerPosition? _parsePosition(String? raw) => switch (raw) {
        'goalkeeper' => PlayerPosition.goalkeeper,
        'defender' => PlayerPosition.defender,
        'midfielder' => PlayerPosition.midfielder,
        'forward' => PlayerPosition.forward,
        _ => null,
      };

  static SkillLevel? _parseSkillLevel(int? raw) => switch (raw) {
        1 => SkillLevel.beginner,
        2 => SkillLevel.recreational,
        3 => SkillLevel.intermediate,
        4 => SkillLevel.advanced,
        5 => SkillLevel.competitive,
        _ => null,
      };
}
