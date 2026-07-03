import 'package:dio/dio.dart';

import '../error/failure.dart';

class ConnectivityInterceptor extends Interceptor {
  ConnectivityInterceptor({required this.onOnline, required this.onOffline});

  final void Function() onOnline;
  final void Function() onOffline;

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    onOnline();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (isConnectivityError(err)) onOffline();
    handler.next(err);
  }
}
