enum FailureType {
  noConnection,
  timeout,
  server,
  notFound,
  unauthorized,
  cancelled,
  unknown,
}

class Failure implements Exception {
  const Failure({
    required this.message,
    this.statusCode,
    this.type = FailureType.unknown,
  });

  final String message;

  final int? statusCode;

  final FailureType type;

  @override
  String toString() => message;
}

Failure asFailure(Object? error) => error is Failure
    ? error
    : Failure(message: error?.toString() ?? 'Something went wrong.');
