import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/home/data/datasources/home_mock_datasource.dart';

final homeDataSourceProvider = Provider<HomeDataSource>(
  (ref) => HomeMockDataSource(),
);
