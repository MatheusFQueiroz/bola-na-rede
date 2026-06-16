import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/search/data/datasources/search_datasource_provider.dart';
import 'package:bola_na_rede/features/search/data/repositories/search_repository_impl.dart';
import 'package:bola_na_rede/features/search/domain/repositories/search_repository.dart';

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepositoryImpl(
    dataSource: ref.watch(searchDataSourceProvider),
  ),
);
