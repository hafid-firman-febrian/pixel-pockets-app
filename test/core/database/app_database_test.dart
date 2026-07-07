import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('seeds 18 default categories when empty', () async {
    await db.seedDefaultCategoriesIfEmpty();
    final rows = await db.select(db.categories).get();
    expect(rows.length, 18);
    expect(rows.where((c) => c.type == 'income').length, 5);
    expect(rows.where((c) => c.type == 'expense').length, 13);
    expect(rows.first.color, startsWith('#'));
  });

  test('seed is idempotent', () async {
    await db.seedDefaultCategoriesIfEmpty();
    await db.seedDefaultCategoriesIfEmpty();
    final rows = await db.select(db.categories).get();
    expect(rows.length, 18);
  });
}
