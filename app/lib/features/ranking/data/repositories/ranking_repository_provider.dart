import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/ranking/data/datasources/ranking_datasource_provider.dart';
import 'package:bola_na_rede/features/ranking/data/repositories/ranking_repository_impl.dart';
import 'package:bola_na_rede/features/ranking/domain/repositories/ranking_repository.dart';

final rankingRepositoryProvider = Provider<RankingRepository>(
  (ref) => RankingRepositoryImpl(
    dataSource: ref.watch(rankingDataSourceProvider),
  ),
);
