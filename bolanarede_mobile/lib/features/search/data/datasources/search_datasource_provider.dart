import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/search/data/datasources/search_http_datasource.dart';
import 'package:bola_na_rede/features/search/data/datasources/search_mock_datasource.dart';

final searchDataSourceProvider = Provider<SearchDataSource>(
  (ref) => SearchHttpDataSource(dio: ref.watch(dioProvider)),
);
