import 'package:dio/dio.dart';

import 'package:bola_na_rede/core/network/interceptors/error_interceptor.dart';

/// Extrai a mensagem amigável de qualquer erro vindo da camada de rede.
///
/// Ordem de resolução:
///   DioException.error (ApiException) → failure.message
///   ApiException direto               → failure.message
///   fallback                          → mensagem padrão fornecida
String errorMessage(Object? error, {String fallback = 'Erro desconhecido.'}) {
  if (error is DioException && error.error is ApiException) {
    return (error.error! as ApiException).failure.message;
  }
  if (error is ApiException) return error.failure.message;
  return fallback;
}
