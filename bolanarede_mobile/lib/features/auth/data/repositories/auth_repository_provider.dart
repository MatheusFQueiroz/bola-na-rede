import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/auth/data/datasources/auth_datasource_provider.dart';
import 'package:bola_na_rede/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bola_na_rede/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    dataSource: ref.watch(authDataSourceProvider),
  ),
);
