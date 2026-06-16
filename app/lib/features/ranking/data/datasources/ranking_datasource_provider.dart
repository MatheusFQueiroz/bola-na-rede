import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/ranking/data/datasources/ranking_mock_datasource.dart';

final rankingDataSourceProvider = Provider<RankingDataSource>(
  (ref) => RankingMockDataSource(),
);
