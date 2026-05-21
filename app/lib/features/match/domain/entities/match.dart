import 'package:json_annotation/json_annotation.dart';
import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/core/shared/snapshots.dart';

part 'match.g.dart';

// ---------------------------------------------------------------------------
// Match
// Tabela: game-service → matches
// Criado quando um MatchProposal é aceito (evento MatchAccepted)
// ---------------------------------------------------------------------------

@JsonSerializable()
class Match {
  /// = matches.external_id (UUID)
  final String id;

  /// = match_proposals.external_id
  @JsonKey(name: 'proposal_id')
  final String proposalId;

  /// = teams.external_id
  @JsonKey(name: 'team_a_id')
  final String teamAId;

  /// = teams.external_id
  @JsonKey(name: 'team_b_id')
  final String teamBId;

  /// Snapshots imutáveis dos times no momento da aceitação
  @JsonKey(name: 'team_a_snapshot')
  final TeamSnapshot? teamASnapshot;

  @JsonKey(name: 'team_b_snapshot')
  final TeamSnapshot? teamBSnapshot;

  /// = fields.external_id
  @JsonKey(name: 'field_id')
  final String? fieldId;

  @JsonKey(name: 'field_snapshot')
  final FieldSnapshot? fieldSnapshot;

  @JsonKey(name: 'scheduled_date')
  final DateTime scheduledDate;

  @JsonKey(name: 'scheduled_time_start')
  final String scheduledTimeStart; // HH:mm

  @JsonKey(name: 'scheduled_time_end')
  final String scheduledTimeEnd; // HH:mm

  final MatchStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Match({
    required this.id,
    required this.proposalId,
    required this.teamAId,
    required this.teamBId,
    this.teamASnapshot,
    this.teamBSnapshot,
    this.fieldId,
    this.fieldSnapshot,
    required this.scheduledDate,
    required this.scheduledTimeStart,
    required this.scheduledTimeEnd,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) => _$MatchFromJson(json);

  Map<String, dynamic> toJson() => _$MatchToJson(this);
}
