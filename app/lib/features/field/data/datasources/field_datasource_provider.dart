import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/field/data/datasources/field_mock_datasource.dart';

final fieldDataSourceProvider = Provider<FieldDataSource>(
  (ref) => FieldMockDataSource(),
);
