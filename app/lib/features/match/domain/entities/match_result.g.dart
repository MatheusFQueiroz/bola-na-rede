// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchResult _$MatchResultFromJson(Map<String, dynamic> json) => MatchResult(
      id: json['id'] as String,
      matchId: json['match_id'] as String,
      scoreTeamA: (json['score_team_a'] as num).toInt(),
      scoreTeamB: (json['score_team_b'] as num).toInt(),
      registeredByTeamId: json['registered_by_team_id'] as String,
      status: $enumDecode(_$MatchResultStatusEnumMap, json['status']),
      registeredAt: DateTime.parse(json['registered_at'] as String),
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.parse(json['confirmed_at'] as String),
      autoAcceptAfter: json['auto_accept_after'] == null
          ? null
          : DateTime.parse(json['auto_accept_after'] as String),
    );

Map<String, dynamic> _$MatchResultToJson(MatchResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_id': instance.matchId,
      'score_team_a': instance.scoreTeamA,
      'score_team_b': instance.scoreTeamB,
      'registered_by_team_id': instance.registeredByTeamId,
      'status': _$MatchResultStatusEnumMap[instance.status]!,
      'registered_at': instance.registeredAt.toIso8601String(),
      'confirmed_at': instance.confirmedAt?.toIso8601String(),
      'auto_accept_after': instance.autoAcceptAfter?.toIso8601String(),
    };

const _$MatchResultStatusEnumMap = {
  MatchResultStatus.pendingConfirmation: 'PENDING_CONFIRMATION',
  MatchResultStatus.confirmed: 'CONFIRMED',
  MatchResultStatus.disputed: 'DISPUTED',
  MatchResultStatus.autoAccepted: 'AUTO_ACCEPTED',
};

ResultConfirmation _$ResultConfirmationFromJson(Map<String, dynamic> json) =>
    ResultConfirmation(
      id: json['id'] as String,
      matchResultId: json['match_result_id'] as String,
      teamId: json['team_id'] as String,
      confirmed: json['confirmed'] as bool,
      respondedAt: DateTime.parse(json['responded_at'] as String),
    );

Map<String, dynamic> _$ResultConfirmationToJson(ResultConfirmation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_result_id': instance.matchResultId,
      'team_id': instance.teamId,
      'confirmed': instance.confirmed,
      'responded_at': instance.respondedAt.toIso8601String(),
    };
