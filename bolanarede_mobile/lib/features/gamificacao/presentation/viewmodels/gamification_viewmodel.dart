import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/gamificacao/data/repositories/gamification_repository_provider.dart';
import 'package:bola_na_rede/features/gamificacao/domain/entities/player_gamification.dart';

final playerGamificationProvider =
    FutureProvider.family<PlayerGamification, String>(
  (ref, userId) =>
      ref.watch(gamificationRepositoryProvider).getProfile(userId),
);
