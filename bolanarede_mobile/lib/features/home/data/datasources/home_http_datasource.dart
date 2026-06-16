import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/shared/enums.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';
import 'package:bola_na_rede/features/match/data/models/game_model.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/team/data/models/team_model.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class HomeHttpDataSource implements HomeDataSource {
  const HomeHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<Match?> getNextMatch(String teamId) async {
    if (teamId.isEmpty) return null;
    final response = await dio.get<List<dynamic>>('/v1/games');
    final now = DateTime.now();
    for (final item in response.data ?? []) {
      final match =
          GameModel.fromJson(item as Map<String, dynamic>).toEntity();
      if (match.status == MatchStatus.scheduled &&
          match.scheduledDate.isAfter(now) &&
          (match.teamAId == teamId || match.teamBId == teamId)) {
        return match;
      }
    }
    return null;
  }

  @override
  Future<Match?> getPendingRequest(String teamId) async => null;

  @override
  Future<Team?> getMyTeam(String teamId) async {
    if (teamId.isEmpty) return null;
    final response =
        await dio.get<Map<String, dynamic>>('/v1/teams/$teamId');
    return TeamModel.fromJson(response.data!).toEntity();
  }
}
