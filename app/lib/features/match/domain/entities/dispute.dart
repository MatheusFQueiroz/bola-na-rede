import 'package:json_annotation/json_annotation.dart';

import 'package:bola_na_rede/core/shared/enums.dart';

part 'dispute.g.dart';

// Tabela: game-service → disputes
// Aberta quando um time rejeita o resultado registrado pelo adversário
// RN12: somente uma disputa aberta por resultado

@JsonSerializable()
class Dispute {
  final String id;

  @JsonKey(name: 'match_result_id')
  final String matchResultId;

  /// = teams.external_id do time que está contestando
  @JsonKey(name: 'disputing_team_id')
  final String disputingTeamId;

  final String reason;
  final DisputeStatus status;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'resolved_at')
  final DateTime? resolvedAt;

  final String? resolution;

  /// = UUID do admin/moderador que resolveu
  @JsonKey(name: 'resolved_by')
  final String? resolvedBy;

  const Dispute({
    required this.id,
    required this.matchResultId,
    required this.disputingTeamId,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
    this.resolution,
    this.resolvedBy,
  });

  factory Dispute.fromJson(Map<String, dynamic> json) =>
      _$DisputeFromJson(json);

  Map<String, dynamic> toJson() => _$DisputeToJson(this);
}
