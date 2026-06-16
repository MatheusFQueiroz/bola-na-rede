import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/ranking/data/datasources/ranking_mock_datasource.dart';
import 'package:bola_na_rede/features/ranking/data/models/ranking_model.dart';
import 'package:bola_na_rede/features/ranking/domain/entities/ranking.dart';

class RankingHttpDatasource implements RankingDataSource {
  const RankingHttpDatasource({required this.dio});

  final Dio dio;

  @override
  Future<List<TeamRanking>> getTeamRankings() async => [];

  @override
  Future<List<PlayerRanking>> getPlayerRankings() async {
    final response = await dio.get<List<dynamic>>(
      '/v1/rankings',
      queryParameters: <String, dynamic>{'sport': 'futsal', 'limit': 50},
    );
    return (response.data ?? [])
        .cast<Map<String, dynamic>>()
        .map(LeaderboardEntryModel.fromJson)
        .map((m) => m.toPlayerEntity())
        .toList();
  }
}
