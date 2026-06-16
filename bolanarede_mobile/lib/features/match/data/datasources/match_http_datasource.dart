import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';
import 'package:bola_na_rede/features/match/data/models/game_model.dart';
import 'package:bola_na_rede/features/match/data/models/match_request_model.dart';
import 'package:bola_na_rede/features/match/domain/entities/match.dart';
import 'package:bola_na_rede/features/match/domain/entities/match_request.dart';

class MatchHttpDataSource implements MatchDataSource {
  MatchHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<Match>> getMatches() async {
    final res = await dio.get<List<dynamic>>('/v1/games');
    final data = res.data ?? [];
    return data
        .map((e) => GameModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<Match> getMatchById(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/games/$id');
    return GameModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> createMatch(Match match) async {
    await dio.post<Map<String, dynamic>>(
      '/v1/match-requests',
      data: <String, dynamic>{'sport': 'futsal'},
    );
  }

  @override
  Future<List<MatchRequest>> getMatchRequests({String? city}) async {
    final res = await dio.get<List<dynamic>>(
      '/v1/match-requests',
      queryParameters: <String, dynamic>{if (city != null) 'city': city},
    );
    final data = res.data ?? [];
    return data
        .map(
          (e) => MatchRequestModel.fromJson(e as Map<String, dynamic>)
              .toEntity(),
        )
        .toList();
  }

  @override
  Future<MatchRequest> createMatchRequest(String sport) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/match-requests',
      data: {'sport': sport},
    );
    return MatchRequestModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> cancelMatchRequest(String requestId) =>
      dio.delete<void>('/v1/match-requests/$requestId');

  @override
  Future<void> acceptMatch(String matchId) =>
      dio.post<void>('/v1/matches/$matchId/accept');

  @override
  Future<Match> getGame(String gameId) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/games/$gameId');
    return GameModel.fromJson(res.data!).toEntity();
  }

  @override
  Future<void> submitResult(
    String gameId, {
    required int playerAGoals,
    required int playerBGoals,
    required int playerAAssists,
    required int playerBAssists,
  }) =>
      dio.post<void>(
        '/v1/games/$gameId/result',
        data: {
          'playerAGoals': playerAGoals,
          'playerBGoals': playerBGoals,
          'playerAAssists': playerAAssists,
          'playerBAssists': playerBAssists,
        },
      );

  @override
  Future<void> confirmResult(String gameId) =>
      dio.post<void>('/v1/games/$gameId/results/confirm');

  @override
  Future<void> disputeResult(String gameId) =>
      dio.post<void>('/v1/games/$gameId/results/dispute');
}
