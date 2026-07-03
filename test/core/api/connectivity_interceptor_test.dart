import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/api/connectivity_interceptor.dart';

void main() {
  test('onResponse marks online', () {
    var online = 0, offline = 0;
    final ic = ConnectivityInterceptor(
      onOnline: () => online++,
      onOffline: () => offline++,
    );
    final options = RequestOptions(path: '/');
    ic.onResponse(
      Response(requestOptions: options, statusCode: 200),
      ResponseInterceptorHandler(),
    );
    expect(online, 1);
    expect(offline, 0);
  });

  test('onError marks offline for a connectivity error', () {
    var online = 0, offline = 0;
    final ic = ConnectivityInterceptor(
      onOnline: () => online++,
      onOffline: () => offline++,
    );
    runZonedGuarded(() {
      ic.onError(
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionError,
        ),
        ErrorInterceptorHandler(),
      );
    }, (error, stack) {});
    expect(offline, 1);
    expect(online, 0);
  });

  test('onError does NOT mark offline for a 500', () {
    var online = 0, offline = 0;
    final ic = ConnectivityInterceptor(
      onOnline: () => online++,
      onOffline: () => offline++,
    );
    final options = RequestOptions(path: '/');
    runZonedGuarded(() {
      ic.onError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: options, statusCode: 500),
        ),
        ErrorInterceptorHandler(),
      );
    }, (error, stack) {});
    expect(offline, 0);
  });
}
