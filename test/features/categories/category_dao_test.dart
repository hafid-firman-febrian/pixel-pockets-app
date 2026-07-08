import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_dao.dart';

void main() {
  late AppDatabase db;
  late CategoryDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = CategoryDao(db);
  });
  tearDown(() => db.close());

  test('create then getAll returns the category', () async {
    final created = await dao.create(name: 'Food', color: '#111111', type: 'expense');
    expect(created.id, greaterThan(0));
    final all = await dao.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'Food');
    expect(all.first.color, '#111111');
    expect(all.first.type, 'expense');
  });

  test('update mutates the row', () async {
    final c = await dao.create(name: 'A', color: '#222222', type: 'expense');
    final updated = await dao.update(id: c.id, name: 'B', color: '#333333', type: 'income');
    expect(updated.name, 'B');
    expect(updated.type, 'income');
  });

  test('delete removes the row', () async {
    final c = await dao.create(name: 'X', color: '#444444', type: 'expense');
    await dao.delete(c.id);
    expect(await dao.getAll(), isEmpty);
  });
}
