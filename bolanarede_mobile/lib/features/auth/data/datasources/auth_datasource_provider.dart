import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_http_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/auth_mock_datasource.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthHttpDataSource(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});
