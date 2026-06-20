import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/ranking/data/datasources/ranking_mock_datasource.dart';
import 'package:bola_na_rede/features/ranking/data/models/ranking_model.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class RankingHttpDatasource implements RankingDataSource {
  const RankingHttpDatasource({required this.dio});

  final Dio dio;

  @override
  Future<List<TeamRanking>> getTeamRankings() async {
    final playerRankings = await getPlayerRankings();
    return playerRankings.asMap().entries.map((e) {
      final p = e.value;
      return TeamRanking(
        id: p.id,
        name: p.name,
        city: '',
        points: p.goals + p.assists,
        wins: 0,
        draws: 0,
        losses: 0,
        goalsFor: p.goals,
        goalsAgainst: 0,
        matchesPlayed: p.matchesPlayed,
        rank: p.rank,
      );
    }).toList();
  }

  @override
  Future<List<PlayerRanking>> getPlayerRankings() async {
    final response = await dio.get<Map<String, dynamic>>(
      '/v1/rankings',
      queryParameters: <String, dynamic>{'sport': 'futsal', 'limit': 50},
    );
    final data = (response.data?['data'] as List<dynamic>?) ?? [];
    return data
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntryModel.fromJson)
        .map((m) => m.toPlayerEntity())
        .toList();
  }
}
