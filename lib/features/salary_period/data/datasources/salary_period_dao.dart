import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/salary_period/domain/models/salary_period_model.dart';

class SalaryPeriodDao {
  SalaryPeriodDao(this._db);

  final AppDatabase _db;

  Future<List<SalaryPeriodModel>> getAll() async {
    final rows = await (_db.select(_db.salaryPeriods)
          ..orderBy([(p) => OrderingTerm.desc(p.startDate)]))
        .get();
    return rows.map(_toModel).toList();
  }

  Future<SalaryPeriodModel> create({
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    final id = await _db.into(_db.salaryPeriods).insert(
          SalaryPeriodsCompanion.insert(
            name: name,
            startDate: startDate,
            endDate: endDate,
            salaryAmount: Value(salaryAmount),
          ),
        );
    return SalaryPeriodModel(
      id: id, name: name, startDate: startDate, endDate: endDate, salaryAmount: salaryAmount,
    );
  }

  Future<SalaryPeriodModel> update({
    required int id,
    required String name,
    required String startDate,
    required String endDate,
    double? salaryAmount,
  }) async {
    await (_db.update(_db.salaryPeriods)..where((p) => p.id.equals(id))).write(
      SalaryPeriodsCompanion(
        name: Value(name),
        startDate: Value(startDate),
        endDate: Value(endDate),
        salaryAmount: Value(salaryAmount),
      ),
    );
    return SalaryPeriodModel(
      id: id, name: name, startDate: startDate, endDate: endDate, salaryAmount: salaryAmount,
    );
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.salaryPeriods)..where((p) => p.id.equals(id))).go();
  }

  SalaryPeriodModel _toModel(SalaryPeriod row) => SalaryPeriodModel(
        id: row.id,
        name: row.name,
        startDate: row.startDate,
        endDate: row.endDate,
        salaryAmount: row.salaryAmount,
      );
}

final salaryPeriodDaoProvider = Provider<SalaryPeriodDao>(
  (ref) => SalaryPeriodDao(ref.watch(appDatabaseProvider)),
);
