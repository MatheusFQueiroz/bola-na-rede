import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/team/data/datasources/team_mock_datasource.dart';

final teamDataSourceProvider = Provider<TeamDataSource>(
  (ref) => TeamMockDataSource(),
);
