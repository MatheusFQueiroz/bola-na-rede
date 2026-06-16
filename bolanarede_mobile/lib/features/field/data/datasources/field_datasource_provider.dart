import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/field/data/datasources/field_http_datasource.dart';
import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';

final fieldDataSourceProvider = Provider<FieldDataSource>(
  (ref) => FieldHttpDataSource(dio: ref.watch(dioProvider)),
);
