// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Match _$MatchFromJson(Map<String, dynamic> json) => Match(
      id: json['id'] as String,
      proposalId: json['proposal_id'] as String,
      teamAId: json['team_a_id'] as String,
      teamBId: json['team_b_id'] as String,
      teamASnapshot: json['team_a_snapshot'] == null
          ? null
          : TeamSnapshot.fromJson(
              json['team_a_snapshot'] as Map<String, dynamic>),
      teamBSnapshot: json['team_b_snapshot'] == null
          ? null
          : TeamSnapshot.fromJson(
              json['team_b_snapshot'] as Map<String, dynamic>),
      fieldId: json['field_id'] as String?,
      fieldSnapshot: json['field_snapshot'] == null
          ? null
          : FieldSnapshot.fromJson(
              json['field_snapshot'] as Map<String, dynamic>),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTimeStart: json['scheduled_time_start'] as String,
      scheduledTimeEnd: json['scheduled_time_end'] as String,
      status: $enumDecode(_$MatchStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MatchToJson(Match instance) => <String, dynamic>{
      'id': instance.id,
      'proposal_id': instance.proposalId,
      'team_a_id': instance.teamAId,
      'team_b_id': instance.teamBId,
      'team_a_snapshot': instance.teamASnapshot,
      'team_b_snapshot': instance.teamBSnapshot,
      'field_id': instance.fieldId,
      'field_snapshot': instance.fieldSnapshot,
      'scheduled_date': instance.scheduledDate.toIso8601String(),
      'scheduled_time_start': instance.scheduledTimeStart,
      'scheduled_time_end': instance.scheduledTimeEnd,
      'status': _$MatchStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$MatchStatusEnumMap = {
  MatchStatus.scheduled: 'SCHEDULED',
  MatchStatus.inProgress: 'IN_PROGRESS',
  MatchStatus.completed: 'COMPLETED',
  MatchStatus.cancelled: 'CANCELLED',
  MatchStatus.noShow: 'NO_SHOW',
};
