import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/auth/data/datasources/token_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('save then read returns the stored tokens', () async {
    final ds = TokenLocalDataSource();
    await ds.save(accessToken: 'a1', refreshToken: 'r1', userName: 'Hafid');
    expect(await ds.readAccessToken(), 'a1');
    expect(await ds.readRefreshToken(), 'r1');
    expect(await ds.readUserName(), 'Hafid');
  });

  test('clear removes everything', () async {
    final ds = TokenLocalDataSource();
    await ds.save(accessToken: 'a1', refreshToken: 'r1');
    await ds.clear();
    expect(await ds.readAccessToken(), isNull);
    expect(await ds.readRefreshToken(), isNull);
    expect(await ds.readUserName(), isNull);
  });
}
