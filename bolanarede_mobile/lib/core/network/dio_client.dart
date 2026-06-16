import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import 'package:bola_na_rede/core/network/interceptors/auth_interceptor.dart';
import 'package:bola_na_rede/core/network/interceptors/error_interceptor.dart';
import 'package:bola_na_rede/features/auth/data/datasources/token_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(tokenStorage: tokenStorage),
    ErrorInterceptor(),
    if (kDebugMode)
      PrettyDioLogger(
        requestHeader: true,
        requestBody: true,
      ),
  ]);

  return dio;
});
