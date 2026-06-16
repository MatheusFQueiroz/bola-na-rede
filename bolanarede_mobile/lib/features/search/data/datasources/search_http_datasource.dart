import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/match/data/models/game_model.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/search/data/datasources/search_mock_datasource.dart';
import 'package:bola_na_rede/features/team/data/models/team_model.dart';
import 'package:bola_na_rede/features/team/domain/entities/team.dart';

class SearchHttpDataSource implements SearchDataSource {
  SearchHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Match>> searchMatches(String query) async {
    final res = await dio.get<List<dynamic>>('/v1/games');
    final data = res.data ?? [];
    final all = data
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all.where((m) {
      final teamA = m.teamASnapshot?.name.toLowerCase() ?? '';
      final teamB = m.teamBSnapshot?.name.toLowerCase() ?? '';
      final field = m.fieldSnapshot?.name.toLowerCase() ?? '';
      return teamA.contains(q) || teamB.contains(q) || field.contains(q);
    }).toList();
  }

  @override
  Future<List<Team>> searchTeams(String query) async {
    final res = await dio.get<List<dynamic>>('/v1/teams');
    final data = res.data ?? [];
    final all = data
        .map((e) => TeamModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
    if (query.isEmpty) return all;
    final q = query.toLowerCase();
    return all
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) ||
              t.city.toLowerCase().contains(q),
        )
        .toList();
  }
}
