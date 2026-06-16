// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      status: $enumDecode(_$UserStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'phone': instance.phone,
      'status': _$UserStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$UserStatusEnumMap = {
  UserStatus.active: 'ACTIVE',
  UserStatus.anonymized: 'ANONYMIZED',
};

PlayerProfile _$PlayerProfileFromJson(Map<String, dynamic> json) =>
    PlayerProfile(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      photoUrl: json['photo_url'] as String?,
      bio: json['bio'] as String?,
      city: json['city'] as String?,
      position: $enumDecodeNullable(_$PlayerPositionEnumMap, json['position']),
      skillLevel: $enumDecodeNullable(_$SkillLevelEnumMap, json['skill_level']),
      isPublic: json['is_public'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$PlayerProfileToJson(PlayerProfile instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'display_name': instance.displayName,
      'photo_url': instance.photoUrl,
      'bio': instance.bio,
      'city': instance.city,
      'position': _$PlayerPositionEnumMap[instance.position],
      'skill_level': _$SkillLevelEnumMap[instance.skillLevel],
      'is_public': instance.isPublic,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$PlayerPositionEnumMap = {
  PlayerPosition.goalkeeper: 'goalkeeper',
  PlayerPosition.defender: 'defender',
  PlayerPosition.midfielder: 'midfielder',
  PlayerPosition.forward: 'forward',
};

const _$SkillLevelEnumMap = {
  SkillLevel.beginner: 1,
  SkillLevel.recreational: 2,
  SkillLevel.intermediate: 3,
  SkillLevel.advanced: 4,
  SkillLevel.competitive: 5,
};

DeviceToken _$DeviceTokenFromJson(Map<String, dynamic> json) => DeviceToken(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: $enumDecode(_$DevicePlatformEnumMap, json['platform']),
      isActive: json['is_active'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$DeviceTokenToJson(DeviceToken instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'token': instance.token,
      'platform': _$DevicePlatformEnumMap[instance.platform]!,
      'is_active': instance.isActive,
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$DevicePlatformEnumMap = {
  DevicePlatform.ios: 'ios',
  DevicePlatform.android: 'android',
};
