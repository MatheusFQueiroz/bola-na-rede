import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/field/data/datasources/field_datasource_provider.dart';
import 'package:bola_na_rede/features/field/data/repositories/field_repository_impl.dart';
import 'package:bola_na_rede/features/field/domain/repositories/field_repository.dart';

final fieldRepositoryProvider = Provider<FieldRepository>(
  (ref) => FieldRepositoryImpl(dataSource: ref.watch(fieldDataSourceProvider)),
);
