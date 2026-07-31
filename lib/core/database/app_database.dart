import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'default_categories.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, SalaryPeriods, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<void> seedDefaultCategoriesIfEmpty() async {
    final count = await customSelect(
      'SELECT COUNT(*) AS c FROM categories',
      readsFrom: {categories},
    ).getSingle();
    if (count.data['c'] as int > 0) return;

    await batch((b) {
      for (var i = 0; i < defaultCategories.length; i++) {
        final c = defaultCategories[i];
        b.insert(
          categories,
          CategoriesCompanion.insert(
            id: Value(i + 1),
            name: c.name,
            color: Value(c.color),
            type: c.type,
          ),
        );
      }
    });
  }

  Future<void> replaceAll({
    required List<CategoriesCompanion> categories,
    required List<SalaryPeriodsCompanion> salaryPeriods,
    required List<TransactionsCompanion> transactions,
  }) async {
    await transaction(() async {
      await delete(this.transactions).go();
      await delete(this.salaryPeriods).go();
      await delete(this.categories).go();
      await batch((b) {
        b.insertAll(
          this.categories,
          categories,
          mode: InsertMode.insertOrReplace,
        );
        b.insertAll(
          this.salaryPeriods,
          salaryPeriods,
          mode: InsertMode.insertOrReplace,
        );
        b.insertAll(
          this.transactions,
          transactions,
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  Future<void> wipeAllData() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(salaryPeriods).go();
      await delete(categories).go();
      await seedDefaultCategoriesIfEmpty();
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pixel_pocket.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
