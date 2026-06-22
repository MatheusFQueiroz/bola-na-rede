import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/errors/failures.dart';

class ApiException implements Exception {
  const ApiException(this.failure);
  final Failure failure;

  @override
  String toString() => failure.message;
}

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final failure = _map(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException(failure),
        type: err.type,
        response: err.response,
      ),
    );
  }

  Failure _map(DioException err) {
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    final status = err.response?.statusCode;
    final body = err.response?.data;
    final message = body is Map
        ? (body['message'] as Object? ?? 'Erro desconhecido.').toString()
        : 'Erro desconhecido.';
    return switch (status) {
      400 => ValidationFailure(message),
      401 when err.requestOptions.path.contains('/auth/login') =>
          ValidationFailure('Email ou senha incorretos.'),
      401 => const UnauthorizedFailure(),
      403 => const ServerFailure('Permissão negada.', statusCode: 403),
      404 => const NotFoundFailure(),
      _ => ServerFailure(message, statusCode: status),
    };
  }
}
