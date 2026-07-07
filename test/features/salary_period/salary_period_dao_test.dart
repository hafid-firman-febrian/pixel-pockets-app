import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_dao.dart';

void main() {
  late AppDatabase db;
  late SalaryPeriodDao dao;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = SalaryPeriodDao(db);
  });
  tearDown(() => db.close());

  test('create then getAll', () async {
    final p = await dao.create(
      name: 'July', startDate: '2026-07-01', endDate: '2026-07-31', salaryAmount: 5000,
    );
    expect(p.id, greaterThan(0));
    final all = await dao.getAll();
    expect(all.length, 1);
    expect(all.first.name, 'July');
    expect(all.first.salaryAmount, 5000);
  });

  test('update and delete', () async {
    final p = await dao.create(
      name: 'A', startDate: '2026-07-01', endDate: '2026-07-31', salaryAmount: null,
    );
    final u = await dao.update(
      id: p.id, name: 'B', startDate: '2026-08-01', endDate: '2026-08-31', salaryAmount: 100,
    );
    expect(u.name, 'B');
    expect(u.salaryAmount, 100);
    await dao.delete(p.id);
    expect(await dao.getAll(), isEmpty);
  });
}
