import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/home/data/datasources/home_datasource_provider.dart';
import 'package:bola_na_rede/features/home/data/repositories/home_repository_impl.dart';
import 'package:bola_na_rede/features/home/domain/repositories/home_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepositoryImpl(dataSource: ref.watch(homeDataSourceProvider)),
);
