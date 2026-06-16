import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/match/data/datasources/match_datasource_provider.dart';
import 'package:bola_na_rede/features/match/data/repositories/match_repository_impl.dart';
import 'package:bola_na_rede/features/match/domain/repositories/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>(
  (ref) => MatchRepositoryImpl(
    dataSource: ref.watch(matchDataSourceProvider),
  ),
);
