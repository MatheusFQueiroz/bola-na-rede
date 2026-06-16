import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';

abstract class GamificationRepository {
  Future<PlayerGamification> getProfile(String userId);
}
