import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/team/data/datasources/team_datasource_provider.dart';
import 'package:bola_na_rede/features/team/data/repositories/team_repository_impl.dart';
import 'package:bola_na_rede/features/team/domain/repositories/team_repository.dart';

final teamRepositoryProvider = Provider<TeamRepository>(
  (ref) => TeamRepositoryImpl(dataSource: ref.watch(teamDataSourceProvider)),
);
