// lib/features/match/domain/entities/match.dart

class MatchPlayer {
  final String id;
  final String name;
  final String initials;
  final int goals;
  final int assists;

  const MatchPlayer({
    required this.id,
    required this.name,
    required this.initials,
    this.goals = 0,
    this.assists = 0,
  });

  MatchPlayer copyWith({int? goals, int? assists}) => MatchPlayer(
        id: id,
        name: name,
        initials: initials,
        goals: goals ?? this.goals,
        assists: assists ?? this.assists,
      );
}

class Match {
  final String id;
  final String teamAName;
  final String teamAInitials;
  final String teamBName;
  final String teamBInitials;
  final String date;
  final String time;
  final String location;
  final String modality;
  final String status; // confirmed | pending | waiting | cancelled
  final int scoreA;
  final int scoreB;
  final List<MatchPlayer> playersA;
  final List<MatchPlayer> playersB;
  final int maxPlayersA;
  final int maxPlayersB;

  const Match({
    required this.id,
    required this.teamAName,
    required this.teamAInitials,
    required this.teamBName,
    required this.teamBInitials,
    required this.date,
    required this.time,
    required this.location,
    required this.modality,
    required this.status,
    this.scoreA = 0,
    this.scoreB = 0,
    this.playersA = const [],
    this.playersB = const [],
    this.maxPlayersA = 8,
    this.maxPlayersB = 8,
  });
}
