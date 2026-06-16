import 'package:dio/dio.dart';

import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_datasource.dart';
import 'package:bola_na_rede/features/gamificacao/data/models/gamification_model.dart';
import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';

class GamificationHttpDatasource implements GamificationDataSource {
  const GamificationHttpDatasource({required this.dio});

  final Dio dio;

  @override
  Future<PlayerGamification> getProfile(String userId) async {
    final response =
        await dio.get<Map<String, dynamic>>('/v1/profiles/$userId');
    return GamificationModel.fromJson(response.data!).toEntity();
  }
}
