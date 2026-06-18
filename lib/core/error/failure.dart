import 'package:dio/dio.dart';

/// Kategori error yang UI-friendly. Screen memilih ikon/perlakuan berdasarkan
/// ini tanpa perlu tahu soal Dio.
enum FailureType {
  noConnection, // tidak ada koneksi sama sekali
  timeout, // waktu habis menunggu response
  server, // 5xx — server bermasalah
  notFound, // 404
  unauthorized, // 401 / 403
  cancelled, // request dibatalkan
  unknown, // selain di atas
}

/// A normalized, UI-safe error.
///
/// Repositories catch low-level [DioException]s and rethrow a [Failure] so
/// that providers and screens never need to know about Dio. The API wraps
/// errors as `{ "error": "pesan" }`; [Failure.fromDio] extracts that message.
class Failure implements Exception {
  const Failure({
    required this.message,
    this.statusCode,
    this.type = FailureType.unknown,
  });

  /// Human-readable message, safe to show to the user.
  final String message;

  /// HTTP status code when the failure originated from a server response.
  final int? statusCode;

  /// Coarse category so the UI can branch (icon, retry affordance, etc.).
  final FailureType type;

  /// Builds a [Failure] from a [DioException], pulling the server's
  /// `{ "error": "..." }` message when present and mapping transport-level
  /// problems (timeouts, connectivity) to friendly text + a [FailureType].
  factory Failure.fromDio(DioException e) {
    final response = e.response;

    // Server replied with a body — prefer its "error" field.
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

    // No response — transport-level problem.
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
