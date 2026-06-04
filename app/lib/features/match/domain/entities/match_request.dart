import 'package:json_annotation/json_annotation.dart';

import 'package:bola_na_rede/core/shared/enums.dart';

part 'match_request.g.dart';

// Tabela: matchmaking-service → match_requests
// Regras: RN05 — máx 3 requests PENDING por time; expira em 48h

@JsonSerializable()
class MatchRequest {
  /// = match_requests.external_id (UUID)
  final String id;

  /// = teams.external_id
  @JsonKey(name: 'requesting_team_id')
  final String requestingTeamId;

  @JsonKey(name: 'preferred_date')
  final DateTime preferredDate;

  @JsonKey(name: 'preferred_time_start')
  final String preferredTimeStart; // HH:mm

  @JsonKey(name: 'preferred_time_end')
  final String preferredTimeEnd; // HH:mm

  @JsonKey(name: 'preferred_city')
  final String preferredCity;

  @JsonKey(name: 'location_range_km')
  final double locationRangeKm;

  final MatchRequestStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  /// Expira em 48h após criação (RN05)
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const MatchRequest({
    required this.id,
    required this.requestingTeamId,
    required this.preferredDate,
    required this.preferredTimeStart,
    required this.preferredTimeEnd,
    required this.preferredCity,
    required this.locationRangeKm,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.updatedAt,
  });

  factory MatchRequest.fromJson(Map<String, dynamic> json) =>
      _$MatchRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MatchRequestToJson(this);
}

// Tabela: matchmaking-service → match_proposals
// Expira em 48h (RN05)

@JsonSerializable()
class MatchProposal {
  /// = match_proposals.external_id (UUID)
  final String id;

  @JsonKey(name: 'match_request_id')
  final String matchRequestId;

  /// = teams.external_id do time que está propondo
  @JsonKey(name: 'proposing_team_id')
  final String proposingTeamId;

  /// = fields.external_id — opcional
  @JsonKey(name: 'field_id')
  final String? fieldId;

  @JsonKey(name: 'proposed_date')
  final DateTime proposedDate;

  @JsonKey(name: 'proposed_time_start')
  final String proposedTimeStart; // HH:mm

  @JsonKey(name: 'proposed_time_end')
  final String proposedTimeEnd; // HH:mm

  final MatchProposalStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @JsonKey(name: 'responded_at')
  final DateTime? respondedAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  const MatchProposal({
    required this.id,
    required this.matchRequestId,
    required this.proposingTeamId,
    this.fieldId,
    required this.proposedDate,
    required this.proposedTimeStart,
    required this.proposedTimeEnd,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
  });

  factory MatchProposal.fromJson(Map<String, dynamic> json) =>
      _$MatchProposalFromJson(json);

  Map<String, dynamic> toJson() => _$MatchProposalToJson(this);
}
