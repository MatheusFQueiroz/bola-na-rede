import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_http_datasource.dart';
import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';

final homeDataSourceProvider = Provider<HomeDataSource>(
  (ref) => HomeHttpDataSource(dio: ref.watch(dioProvider)),
);
