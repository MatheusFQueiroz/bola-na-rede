sealed class Failure {
  const Failure(this.message);
  final String message;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão com a internet.']);
}

class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Sessão expirada. Faça login novamente.',
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Recurso não encontrado.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
