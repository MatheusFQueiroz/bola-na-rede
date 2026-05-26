class TeamRanking {
  final String id;
  final String name;
  final String city;
  final int points;
  final int wins;
  final int draws;
  final int losses;
  final int goalsFor;
  final int goalsAgainst;
  final int matchesPlayed;
  final int rank;

  const TeamRanking({
    required this.id,
    required this.name,
    required this.city,
    required this.points,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsFor,
    required this.goalsAgainst,
    required this.matchesPlayed,
    required this.rank,
  });

  int get goalDifference => goalsFor - goalsAgainst;
}

class PlayerRanking {
  final String id;
  final String name;
  final String teamName;
  final String position;
  final int goals;
  final int assists;
  final int matchesPlayed;
  final int rank;

  const PlayerRanking({
    required this.id,
    required this.name,
    required this.teamName,
    required this.position,
    required this.goals,
    required this.assists,
    required this.matchesPlayed,
    required this.rank,
  });
}
