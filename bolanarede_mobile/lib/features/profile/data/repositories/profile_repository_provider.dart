import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/profile/data/datasources/profile_datasource_provider.dart';
import 'package:bola_na_rede/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:bola_na_rede/features/profile/domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) =>
      ProfileRepositoryImpl(dataSource: ref.watch(profileDataSourceProvider)),
);
