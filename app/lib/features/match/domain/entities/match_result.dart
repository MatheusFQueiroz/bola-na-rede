import 'package:json_annotation/json_annotation.dart';
import 'package:bola_na_rede/core/shared/enums.dart';

part 'match_result.g.dart';

// ---------------------------------------------------------------------------
// MatchResult
// Tabela: game-service → match_results
// Regras:
//   RN06 — confirmação bilateral obrigatória
//   RN06 — auto-aceito após 24h sem resposta do adversário
// ---------------------------------------------------------------------------

@JsonSerializable()
class MatchResult {
  final String id;

  @JsonKey(name: 'match_id')
  final String matchId;

  @JsonKey(name: 'score_team_a')
  final int scoreTeamA;

  @JsonKey(name: 'score_team_b')
  final int scoreTeamB;

  /// = teams.external_id do time que registrou o resultado
  @JsonKey(name: 'registered_by_team_id')
  final String registeredByTeamId;

  final MatchResultStatus status;

  @JsonKey(name: 'registered_at')
  final DateTime registeredAt;

  @JsonKey(name: 'confirmed_at')
  final DateTime? confirmedAt;

  /// Janela de 24h para o adversário confirmar ou contestar (RN06)
  @JsonKey(name: 'auto_accept_after')
  final DateTime? autoAcceptAfter;

  bool get isAutoAcceptWindowOpen =>
      autoAcceptAfter != null && DateTime.now().isBefore(autoAcceptAfter!);

  const MatchResult({
    required this.id,
    required this.matchId,
    required this.scoreTeamA,
    required this.scoreTeamB,
    required this.registeredByTeamId,
    required this.status,
    required this.registeredAt,
    this.confirmedAt,
    this.autoAcceptAfter,
  });

  factory MatchResult.fromJson(Map<String, dynamic> json) =>
      _$MatchResultFromJson(json);

  Map<String, dynamic> toJson() => _$MatchResultToJson(this);
}

// ---------------------------------------------------------------------------
// ResultConfirmation
// Tabela: game-service → result_confirmations
// RN06: precisam de 2 confirmações positivas para status = CONFIRMED
// ---------------------------------------------------------------------------

@JsonSerializable()
class ResultConfirmation {
  final String id;

  @JsonKey(name: 'match_result_id')
  final String matchResultId;

  /// = teams.external_id do time que está respondendo
  @JsonKey(name: 'team_id')
  final String teamId;

  /// true = confirmou; false = contestou (abre disputa)
  final bool confirmed;

  @JsonKey(name: 'responded_at')
  final DateTime respondedAt;

  const ResultConfirmation({
    required this.id,
    required this.matchResultId,
    required this.teamId,
    required this.confirmed,
    required this.respondedAt,
  });

  factory ResultConfirmation.fromJson(Map<String, dynamic> json) =>
      _$ResultConfirmationFromJson(json);

  Map<String, dynamic> toJson() => _$ResultConfirmationToJson(this);
}
