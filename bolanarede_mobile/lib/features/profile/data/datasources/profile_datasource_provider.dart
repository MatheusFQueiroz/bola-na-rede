import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/features/profile/data/datasources/profile_mock_datasource.dart';

final profileDataSourceProvider = Provider<ProfileDataSource>(
  (ref) => ProfileMockDataSource(),
);
