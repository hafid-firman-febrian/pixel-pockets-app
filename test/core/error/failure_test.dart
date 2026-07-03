import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/error/failure.dart';

void main() {
  group('isConnectivityError', () {
    DioException dio(DioExceptionType type, {Response? response}) =>
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: type,
          response: response,
        );

    test('true for connection/timeout errors with no response', () {
      expect(
        isConnectivityError(dio(DioExceptionType.connectionError)),
        isTrue,
      );
      expect(
        isConnectivityError(dio(DioExceptionType.connectionTimeout)),
        isTrue,
      );
      expect(isConnectivityError(dio(DioExceptionType.sendTimeout)), isTrue);
      expect(isConnectivityError(dio(DioExceptionType.receiveTimeout)), isTrue);
    });

    test('false when the server responded (e.g. 500)', () {
      final e = dio(
        DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 500,
        ),
      );
      expect(isConnectivityError(e), isFalse);
    });

    test('false for cancel', () {
      expect(isConnectivityError(dio(DioExceptionType.cancel)), isFalse);
    });
  });

  group('asFailure', () {
    test('returns the same Failure instance untouched', () {
      const failure = Failure(message: 'boom', type: FailureType.server);
      expect(asFailure(failure), same(failure));
    });

    test('wraps a non-Failure error with its string form', () {
      final result = asFailure(StateError('nope'));
      expect(result.message, contains('nope'));
      expect(result.type, FailureType.unknown);
    });

    test('wraps null with a generic message', () {
      final result = asFailure(null);
      expect(result.message, 'Something went wrong.');
      expect(result.type, FailureType.unknown);
    });
  });
}
