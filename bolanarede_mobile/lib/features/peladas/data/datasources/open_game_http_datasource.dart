import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/peladas/data/models/open_game_model.dart';
import 'package:bola_na_rede/features/peladas/domain/entities/open_game.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

class OpenGameHttpDataSource implements OpenGameRepository {
  OpenGameHttpDataSource({required this.dio});

  final Dio dio;

  @override
  Future<List<OpenGame>> getOpenGames({String? sport}) async {
    final res = await dio.get<Map<String, dynamic>>(
      '/v1/open-games',
      queryParameters: <String, dynamic>{
        if (sport != null) 'sport': sport,
      },
    );
    final data = (res.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => OpenGameModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<OpenGame> getOpenGameById(String id) async {
    final res = await dio.get<Map<String, dynamic>>('/v1/open-games/$id');
    return OpenGameModel.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<OpenGame> createOpenGame({
    required String title,
    required String sport,
    required String scheduledAt,
    int? durationMinutes,
    int? minPlayers,
    int? maxPlayers,
    String? fieldId,
    String? description,
  }) async {
    final res = await dio.post<Map<String, dynamic>>(
      '/v1/open-games',
      data: <String, dynamic>{
        'title': title,
        'sport': sport,
        'scheduledAt': scheduledAt,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        if (minPlayers != null) 'minPlayers': minPlayers,
        if (maxPlayers != null) 'maxPlayers': maxPlayers,
        if (fieldId != null) 'fieldId': fieldId,
        if (description != null) 'description': description,
      },
    );
    return OpenGameModel.fromJson(
      res.data!['data'] as Map<String, dynamic>,
    ).toEntity();
  }

  @override
  Future<void> joinOpenGame(String id) =>
      dio.post<void>('/v1/open-games/$id/join');

  @override
  Future<void> leaveOpenGame(String id) =>
      dio.delete<void>('/v1/open-games/$id/leave');

  @override
  Future<void> cancelOpenGame(String id) =>
      dio.delete<void>('/v1/open-games/$id');
}
