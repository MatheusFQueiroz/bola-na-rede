import 'package:json_annotation/json_annotation.dart';
import 'package:bola_na_rede/core/shared/enums.dart';

part 'user.g.dart';

// ---------------------------------------------------------------------------
// User
// Tabela: identity-service → users
// ---------------------------------------------------------------------------

enum UserStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('ANONYMIZED')
  anonymized,
}

@JsonSerializable()
class User {
  /// = users.external_id (UUID)
  final String id;

  final String? email;
  final String? phone;
  final UserStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const User({
    required this.id,
    this.email,
    this.phone,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

// ---------------------------------------------------------------------------
// PlayerProfile
// Tabela: identity-service → player_profiles
// Nota: player_score NÃO vive aqui — fica no social-service
// ---------------------------------------------------------------------------

@JsonSerializable()
class PlayerProfile {
  /// = users.external_id
  @JsonKey(name: 'user_id')
  final String userId;

  @JsonKey(name: 'display_name')
  final String displayName;

  @JsonKey(name: 'photo_url')
  final String? photoUrl;

  final String? bio;
  final String? city;
  final PlayerPosition? position;

  @JsonKey(name: 'skill_level')
  final SkillLevel? skillLevel;

  @JsonKey(name: 'is_public')
  final bool isPublic;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const PlayerProfile({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.city,
    this.position,
    this.skillLevel,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlayerProfile.fromJson(Map<String, dynamic> json) =>
      _$PlayerProfileFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerProfileToJson(this);
}

// ---------------------------------------------------------------------------
// DeviceToken
// Tabela: identity-service → device_tokens
// ---------------------------------------------------------------------------

enum DevicePlatform {
  @JsonValue('ios')
  ios,
  @JsonValue('android')
  android,
}

@JsonSerializable()
class DeviceToken {
  @JsonKey(name: 'user_id')
  final String userId;

  final String token;
  final DevicePlatform platform;

  @JsonKey(name: 'is_active')
  final bool isActive;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const DeviceToken({
    required this.userId,
    required this.token,
    required this.platform,
    required this.isActive,
    required this.updatedAt,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) =>
      _$DeviceTokenFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceTokenToJson(this);
}
