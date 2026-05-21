// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dispute.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Dispute _$DisputeFromJson(Map<String, dynamic> json) => Dispute(
      id: json['id'] as String,
      matchResultId: json['match_result_id'] as String,
      disputingTeamId: json['disputing_team_id'] as String,
      reason: json['reason'] as String,
      status: $enumDecode(_$DisputeStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      resolvedAt: json['resolved_at'] == null
          ? null
          : DateTime.parse(json['resolved_at'] as String),
      resolution: json['resolution'] as String?,
      resolvedBy: json['resolved_by'] as String?,
    );

Map<String, dynamic> _$DisputeToJson(Dispute instance) => <String, dynamic>{
      'id': instance.id,
      'match_result_id': instance.matchResultId,
      'disputing_team_id': instance.disputingTeamId,
      'reason': instance.reason,
      'status': _$DisputeStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'resolved_at': instance.resolvedAt?.toIso8601String(),
      'resolution': instance.resolution,
      'resolved_by': instance.resolvedBy,
    };

const _$DisputeStatusEnumMap = {
  DisputeStatus.open: 'OPEN',
  DisputeStatus.resolved: 'RESOLVED',
  DisputeStatus.dismissed: 'DISMISSED',
};
