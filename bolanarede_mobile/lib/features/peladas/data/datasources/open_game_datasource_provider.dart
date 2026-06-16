import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/peladas/data/datasources/open_game_http_datasource.dart';
import 'package:bola_na_rede/features/peladas/domain/repositories/open_game_repository.dart';

final openGameRepositoryProvider = Provider<OpenGameRepository>(
  (ref) => OpenGameHttpDataSource(dio: ref.watch(dioProvider)),
);
