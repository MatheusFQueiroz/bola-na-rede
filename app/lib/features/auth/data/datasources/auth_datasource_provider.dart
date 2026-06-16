import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';

final authDataSourceProvider = Provider<AuthDataSource>(
  (ref) => AuthMockDataSource(),
);
