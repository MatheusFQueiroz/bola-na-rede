import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_http_datasource.dart';
import 'package:bola_na_rede/features/match/data/datasources/match_mock_datasource.dart';

final matchDataSourceProvider = Provider<MatchDataSource>(
  (ref) => MatchHttpDataSource(dio: ref.watch(dioProvider)),
);
