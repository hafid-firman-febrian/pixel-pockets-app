import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_api.dart';

class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.handler);
  final ResponseBody Function(RequestOptions options) handler;
  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<List<int>>? requestStream, Future<void>? cancelFuture) async => handler(options);
  @override
  void close({bool force = false}) {}
}

void main() {
  test('exchangeGoogle posts idToken and parses tokens', () async {
    late RequestOptions captured;
    final dio = Dio(BaseOptions(baseUrl: 'https://x'))
      ..httpClientAdapter = _StubAdapter((o) {
        captured = o;
        return ResponseBody.fromString(
          '{"data":{"accessToken":"a","refreshToken":"r","expiresIn":1800,"user":{"email":"e","sub":"s","name":"n"}}}',
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });
    final api = AuthApi(dio);

    final dto = await api.exchangeGoogle('gid');

    expect(captured.path, '/api/auth/google');
    expect((captured.data as Map)['idToken'], 'gid');
    expect(dto.accessToken, 'a');
    expect(dto.name, 'n');
  });
}
