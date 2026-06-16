import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_datasource.dart';
import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';
import 'package:bola_na_rede/features/gamificacao/domain/repositories/gamification_repository.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  const GamificationRepositoryImpl({required this.dataSource});

  final GamificationDataSource dataSource;

  @override
  Future<PlayerGamification> getProfile(String userId) =>
      dataSource.getProfile(userId);
}
