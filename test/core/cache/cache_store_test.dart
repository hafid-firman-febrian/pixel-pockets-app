import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<CacheStore> store() async =>
      CacheStore(await SharedPreferences.getInstance());

  test('writeJson / readJson round-trips a map', () async {
    final s = await store();
    await s.writeJson('k', {'a': 1, 'b': 'x'});
    expect(s.readJson('k'), {'a': 1, 'b': 'x'});
  });

  test('writeJson / readJsonList round-trips a list', () async {
    final s = await store();
    await s.writeJson('k', [
      {'a': 1},
      {'a': 2},
    ]);
    expect(s.readJsonList('k'), [
      {'a': 1},
      {'a': 2},
    ]);
  });

  test('readJson returns null for a missing key', () async {
    final s = await store();
    expect(s.readJson('missing'), isNull);
  });

  test('removeByPrefix drops only matching keys', () async {
    final s = await store();
    await s.writeJson('cache:transactions:p1', {'a': 1});
    await s.writeJson('cache:transactions:p2', {'a': 2});
    await s.writeJson('cache:categories', {'a': 3});
    await s.removeByPrefix('cache:transactions');
    expect(s.readJson('cache:transactions:p1'), isNull);
    expect(s.readJson('cache:transactions:p2'), isNull);
    expect(s.readJson('cache:categories'), {'a': 3});
  });

  test('clearAll wipes everything', () async {
    final s = await store();
    await s.writeJson('a', {'x': 1});
    await s.clearAll();
    expect(s.readJson('a'), isNull);
  });
}
