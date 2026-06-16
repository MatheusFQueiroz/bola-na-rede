import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bola_na_rede/core/network/dio_client.dart';
import 'package:bola_na_rede/features/social/data/datasources/review_http_datasource.dart';
import 'package:bola_na_rede/features/social/domain/repositories/review_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>(
  (ref) => ReviewHttpDatasource(dio: ref.watch(dioProvider)),
);
