import 'package:dio/dio.dart';

/// A normalized, UI-safe error.
///
/// Repositories catch low-level [DioException]s and rethrow a [Failure] so
/// that providers and screens never need to know about Dio. The API wraps
/// errors as `{ "error": "pesan" }`; [Failure.fromDio] extracts that message.
class Failure implements Exception {
  const Failure({
    required this.message,
    this.statusCode,
  });

  /// Human-readable message, safe to show to the user.
  final String message;

  /// HTTP status code when the failure originated from a server response.
  final int? statusCode;

  /// Builds a [Failure] from a [DioException], pulling the server's
  /// `{ "error": "..." }` message when present and mapping transport-level
  /// problems (timeouts, connectivity) to friendly text.
  factory Failure.fromDio(DioException e) {
    final response = e.response;

    // Server replied with a body — prefer its "error" field.
    if (response != null) {
      final data = response.data;
      String? serverMessage;
      if (data is Map && data['error'] is String) {
        serverMessage = data['error'] as String;
      }
      return Failure(
        message: serverMessage ?? _statusFallback(response.statusCode),
        statusCode: response.statusCode,
      );
    }

    // No response — transport-level problem.
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const Failure(
          message: 'Koneksi timeout. Coba lagi.',
        );
      case DioExceptionType.connectionError:
        return const Failure(
          message: 'Tidak dapat terhubung ke server.',
        );
      case DioExceptionType.cancel:
        return const Failure(message: 'Permintaan dibatalkan.');
      case DioExceptionType.badCertificate:
        return const Failure(message: 'Sertifikat server tidak valid.');
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return Failure(message: e.message ?? 'Terjadi kesalahan tak terduga.');
    }
  }

  static String _statusFallback(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Permintaan tidak valid.';
      case 401:
        return 'Tidak terautorisasi.';
      case 403:
        return 'Akses ditolak.';
      case 404:
        return 'Data tidak ditemukan.';
      case 500:
        return 'Terjadi kesalahan pada server.';
      default:
        return 'Terjadi kesalahan ($statusCode).';
    }
  }

  @override
  String toString() => message;
}
