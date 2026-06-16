import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_datasource_provider.dart';
import 'package:bola_na_rede/features/gamificacao/data/repositories/gamification_repository_impl.dart';
import 'package:bola_na_rede/features/gamificacao/domain/repositories/gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository>(
  (ref) => GamificationRepositoryImpl(
    dataSource: ref.watch(gamificationDataSourceProvider),
  ),
);
