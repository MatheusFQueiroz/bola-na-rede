// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      status: $enumDecode(_$TeamStatusEnumMap, json['status']),
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'status': _$TeamStatusEnumMap[instance.status]!,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$TeamStatusEnumMap = {
  TeamStatus.active: 'ACTIVE',
  TeamStatus.inactive: 'INACTIVE',
  TeamStatus.invalid: 'INVALID',
};

TeamMember _$TeamMemberFromJson(Map<String, dynamic> json) => TeamMember(
      teamId: json['team_id'] as String,
      userId: json['user_id'] as String,
      role: $enumDecode(_$TeamMemberRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      leftAt: json['left_at'] == null
          ? null
          : DateTime.parse(json['left_at'] as String),
    );

Map<String, dynamic> _$TeamMemberToJson(TeamMember instance) =>
    <String, dynamic>{
      'team_id': instance.teamId,
      'user_id': instance.userId,
      'role': _$TeamMemberRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
      'left_at': instance.leftAt?.toIso8601String(),
    };

const _$TeamMemberRoleEnumMap = {
  TeamMemberRole.captain: 'CAPTAIN',
  TeamMemberRole.member: 'MEMBER',
};

TeamSummary _$TeamSummaryFromJson(Map<String, dynamic> json) => TeamSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String,
      rating: (json['rating'] as num).toDouble(),
      playerCount: (json['player_count'] as num).toInt(),
      status: $enumDecode(_$TeamStatusEnumMap, json['status']),
      syncedAt: DateTime.parse(json['synced_at'] as String),
    );

Map<String, dynamic> _$TeamSummaryToJson(TeamSummary instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'city': instance.city,
      'rating': instance.rating,
      'player_count': instance.playerCount,
      'status': _$TeamStatusEnumMap[instance.status]!,
      'synced_at': instance.syncedAt.toIso8601String(),
    };
