import 'package:dio/dio.dart';

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

  factory Failure.fromDio(DioException e) {
    final response = e.response;

    if (response != null) {
      final data = response.data;
      String? serverMessage;
      if (data is Map && data['error'] is String) {
        serverMessage = data['error'] as String;
      }
      final status = response.statusCode;
      return Failure(
        message: serverMessage ?? _statusFallback(status),
        statusCode: status,
        type: _typeFromStatus(status),
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure(
          message: 'Connection timeout. Please try again.',
          type: FailureType.timeout,
        );
      case DioExceptionType.connectionError:
        return const Failure(
          message: 'Connection error. Please try again.',
          type: FailureType.noConnection,
        );
      case DioExceptionType.cancel:
        return const Failure(
          message: 'Request cancelled.',
          type: FailureType.cancelled,
        );
      case DioExceptionType.badCertificate:
        return const Failure(
          message: 'Server certificate is not valid.',
          type: FailureType.unknown,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return Failure(
          message: e.message ?? 'An unexpected error occurred.',
          type: FailureType.unknown,
        );
    }
  }

  static FailureType _typeFromStatus(int? status) {
    if (status == null) return FailureType.unknown;
    if (status >= 500) return FailureType.server;
    switch (status) {
      case 401:
      case 403:
        return FailureType.unauthorized;
      case 404:
        return FailureType.notFound;
      default:
        return FailureType.unknown;
    }
  }

  static String _statusFallback(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Request is not valid.';
      case 401:
        return 'Unauthorized.';
      case 403:
        return 'Access denied.';
      case 404:
        return 'Data not found.';
      case 500:
        return 'An error occurred on the server.';
      default:
        return 'An error occurred ($statusCode).';
    }
  }

  @override
  String toString() => message;
}

Failure asFailure(Object? error) => error is Failure
    ? error
    : Failure(message: error?.toString() ?? 'Something went wrong.');
