// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'match_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MatchRequest _$MatchRequestFromJson(Map<String, dynamic> json) => MatchRequest(
      id: json['id'] as String,
      requestingTeamId: json['requesting_team_id'] as String,
      preferredDate: DateTime.parse(json['preferred_date'] as String),
      preferredTimeStart: json['preferred_time_start'] as String,
      preferredTimeEnd: json['preferred_time_end'] as String,
      preferredCity: json['preferred_city'] as String,
      locationRangeKm: (json['location_range_km'] as num).toDouble(),
      status: $enumDecode(_$MatchRequestStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MatchRequestToJson(MatchRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'requesting_team_id': instance.requestingTeamId,
      'preferred_date': instance.preferredDate.toIso8601String(),
      'preferred_time_start': instance.preferredTimeStart,
      'preferred_time_end': instance.preferredTimeEnd,
      'preferred_city': instance.preferredCity,
      'location_range_km': instance.locationRangeKm,
      'status': _$MatchRequestStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$MatchRequestStatusEnumMap = {
  MatchRequestStatus.pending: 'PENDING',
  MatchRequestStatus.matched: 'MATCHED',
  MatchRequestStatus.expired: 'EXPIRED',
  MatchRequestStatus.cancelled: 'CANCELLED',
};

MatchProposal _$MatchProposalFromJson(Map<String, dynamic> json) =>
    MatchProposal(
      id: json['id'] as String,
      matchRequestId: json['match_request_id'] as String,
      proposingTeamId: json['proposing_team_id'] as String,
      fieldId: json['field_id'] as String?,
      proposedDate: DateTime.parse(json['proposed_date'] as String),
      proposedTimeStart: json['proposed_time_start'] as String,
      proposedTimeEnd: json['proposed_time_end'] as String,
      status: $enumDecode(_$MatchProposalStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
    );

Map<String, dynamic> _$MatchProposalToJson(MatchProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'match_request_id': instance.matchRequestId,
      'proposing_team_id': instance.proposingTeamId,
      'field_id': instance.fieldId,
      'proposed_date': instance.proposedDate.toIso8601String(),
      'proposed_time_start': instance.proposedTimeStart,
      'proposed_time_end': instance.proposedTimeEnd,
      'status': _$MatchProposalStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt.toIso8601String(),
      'expires_at': instance.expiresAt.toIso8601String(),
      'responded_at': instance.respondedAt?.toIso8601String(),
    };

const _$MatchProposalStatusEnumMap = {
  MatchProposalStatus.pending: 'PENDING',
  MatchProposalStatus.accepted: 'ACCEPTED',
  MatchProposalStatus.rejected: 'REJECTED',
  MatchProposalStatus.expired: 'EXPIRED',
};
