import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/data/datasources/auth_api.dart';
import 'package:pixel_pocket/features/auth/data/datasources/token_local_data_source.dart';
import 'package:pixel_pocket/features/auth/data/dtos/auth_session_dto.dart';
import 'package:pixel_pocket/features/auth/data/repositories/auth_session_repository.dart';

class _FakeApi implements AuthApi {
  int refreshCalls = 0;
  @override
  Future<AuthSessionDto> refresh(String refreshToken) async {
    refreshCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return AuthSessionDto(accessToken: 'new-access', refreshToken: 'new-refresh', expiresIn: 1800, email: '', sub: '', name: '');
  }
  @override
  Future<AuthSessionDto> exchangeGoogle(String idToken) async =>
      AuthSessionDto(accessToken: 'a', refreshToken: 'r', expiresIn: 1800, email: 'e', sub: 's', name: 'n');
  @override
  Future<void> logout(String refreshToken) async {}
  @override
  Future<Map<String, dynamic>> me(String accessToken) async => {};
}

class _FakeStore implements TokenLocalDataSource {
  String? access, refresh, userName;
  @override
  Future<void> save({required String accessToken, required String refreshToken, String? userName}) async {
    access = accessToken; refresh = refreshToken; if (userName != null) this.userName = userName;
  }
  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<String?> readUserName() async => userName;
  @override
  Future<void> clear() async { access = refresh = userName = null; }
}

void main() {
  test('concurrent refresh() calls share a single in-flight API call', () async {
    final api = _FakeApi();
    final store = _FakeStore()..refresh = 'old-refresh';
    final repo = AuthSessionRepository(api, store);

    final results = await Future.wait([repo.refresh(), repo.refresh(), repo.refresh()]);

    expect(api.refreshCalls, 1); // single-flight
    expect(results, everyElement('new-access'));
    expect(store.refresh, 'new-refresh'); // rotated token saved
  });

  test('exchangeGoogle stores tokens and userName', () async {
    final store = _FakeStore();
    final repo = AuthSessionRepository(_FakeApi(), store);
    await repo.exchangeGoogle('gid');
    expect(store.access, 'a');
    expect(store.userName, 'n');
  });
}
