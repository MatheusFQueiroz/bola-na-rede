import 'package:json_annotation/json_annotation.dart';

import 'package:bola_na_rede/core/shared/enums.dart';

part 'team.g.dart';

// Tabela: team-service → teams
// Nota: status INVALID quando membros ativos < 5 (RN04)

@JsonSerializable()
class Team {
  /// = teams.external_id (UUID)
  final String id;

  final String name;
  final String city;
  final TeamStatus status;

  /// = users.external_id do criador
  @JsonKey(name: 'created_by')
  final String createdBy;

  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  const Team({
    required this.id,
    required this.name,
    required this.city,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);

  Map<String, dynamic> toJson() => _$TeamToJson(this);
}

// Tabela: team-service → team_members
// Regras: RN02 (máx 3 times por jogador), RN04 (mín 5 membros ativos)
// Membros ativos: left_at == null

@JsonSerializable()
class TeamMember {
  /// = teams.external_id
  @JsonKey(name: 'team_id')
  final String teamId;

  /// = users.external_id
  @JsonKey(name: 'user_id')
  final String userId;

  final TeamMemberRole role;

  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  /// null = membro ativo
  @JsonKey(name: 'left_at')
  final DateTime? leftAt;

  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? displayName;

  bool get isActive => leftAt == null;

  const TeamMember({
    required this.teamId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.leftAt,
    this.displayName,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMemberToJson(this);
}

// Tabela: matchmaking-service → team_summaries (PROJEÇÃO LOCAL)
// Sincronizado via eventos: TeamCreated, PlayerJoined/Left, RankingRecalculated

@JsonSerializable()
class TeamSummary {
  /// = teams.external_id
  final String id;

  final String name;
  final String city;

  /// Rating ELO — atualizado via RankingRecalculated
  final double rating;

  @JsonKey(name: 'player_count')
  final int playerCount;

  final TeamStatus status;

  @JsonKey(name: 'synced_at')
  final DateTime syncedAt;

  const TeamSummary({
    required this.id,
    required this.name,
    required this.city,
    required this.rating,
    required this.playerCount,
    required this.status,
    required this.syncedAt,
  });

  factory TeamSummary.fromJson(Map<String, dynamic> json) =>
      _$TeamSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$TeamSummaryToJson(this);
}
