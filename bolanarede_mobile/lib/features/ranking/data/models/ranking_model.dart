import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class LeaderboardEntryModel {
  const LeaderboardEntryModel({
    required this.position,
    required this.playerUserId,
    required this.displayName,
    required this.sport,
    required this.gamesPlayed,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.goals,
    required this.assists,
    required this.points,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntryModel(
        position: json['position'] as int,
        playerUserId: json['playerUserId'] as String,
        displayName: json['displayName'] as String? ?? '',
        sport: json['sport'] as String,
        gamesPlayed: json['gamesPlayed'] as int,
        wins: json['wins'] as int,
        losses: json['losses'] as int,
        draws: json['draws'] as int,
        goals: json['goals'] as int,
        assists: json['assists'] as int,
        points: json['points'] as int,
      );

  final int position;
  final String playerUserId;
  final String displayName;
  final String sport;
  final int gamesPlayed;
  final int wins;
  final int losses;
  final int draws;
  final int goals;
  final int assists;
  final int points;

  PlayerRanking toPlayerEntity() => PlayerRanking(
        id: playerUserId,
        name: displayName.isNotEmpty ? displayName : _shortId(playerUserId),
        teamName: '',
        position: sport,
        goals: goals,
        assists: assists,
        matchesPlayed: gamesPlayed,
        rank: position,
      );

  static String _shortId(String id) {
    if (id.length <= 8) return id;
    return id.substring(0, 8).toUpperCase();
  }
}
