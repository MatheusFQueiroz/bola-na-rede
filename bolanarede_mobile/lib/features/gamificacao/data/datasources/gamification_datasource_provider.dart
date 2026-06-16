import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_datasource.dart';
import 'package:bola_na_rede/features/gamificacao/data/datasources/gamification_http_datasource.dart';

final gamificationDataSourceProvider = Provider<GamificationDataSource>(
  (ref) => GamificationHttpDatasource(dio: ref.watch(dioProvider)),
);
