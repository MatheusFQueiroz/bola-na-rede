import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';

class GameModel {
  const GameModel({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.sport,
    required this.status,
    required this.createdAt,
    this.matchId,
    this.playerAGoals,
    this.playerBGoals,
    this.playerAAssists,
    this.playerBAssists,
    this.winnerId,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
        id: json['id'] as String,
        userAId: json['userAId'] as String? ?? '',
        userBId: json['userBId'] as String? ?? '',
        sport: json['sport'] as String? ?? 'football',
        status: json['status'] as String? ?? 'SCHEDULED',
        createdAt: json['createdAt'] as String,
        matchId: json['matchId'] as String?,
        playerAGoals: json['playerAGoals'] as int?,
        playerBGoals: json['playerBGoals'] as int?,
        playerAAssists: json['playerAAssists'] as int?,
        playerBAssists: json['playerBAssists'] as int?,
        winnerId: json['winnerId'] as String?,
      );

  final String id;
  final String? matchId;
  final String userAId;
  final String userBId;
  final String sport;
  final String status;
  final int? playerAGoals;
  final int? playerBGoals;
  final int? playerAAssists;
  final int? playerBAssists;
  final String? winnerId;
  final String createdAt;

  Match toEntity() {
    final ts = DateTime.parse(createdAt);
    return Match(
      id: id,
      proposalId: matchId ?? '',
      teamAId: userAId,
      teamBId: userBId,
      scheduledDate: ts,
      scheduledTimeStart: '',
      scheduledTimeEnd: '',
      status: _parseStatus(status),
      createdAt: ts,
      updatedAt: ts,
      sport: sport,
      playerAGoals: playerAGoals,
      playerBGoals: playerBGoals,
      playerAAssists: playerAAssists,
      playerBAssists: playerBAssists,
      winnerId: winnerId,
    );
  }

  static MatchStatus _parseStatus(String raw) => switch (raw) {
        'IN_PROGRESS' => MatchStatus.inProgress,
        'COMPLETED' => MatchStatus.completed,
        'CANCELLED' => MatchStatus.cancelled,
        'NO_SHOW' => MatchStatus.noShow,
        _ => MatchStatus.scheduled,
      };
}
