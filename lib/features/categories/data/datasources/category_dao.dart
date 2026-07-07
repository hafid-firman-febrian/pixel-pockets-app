import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

class CategoryDao {
  CategoryDao(this._db);

  final AppDatabase _db;

  Future<List<CategoryModel>> getAll() async {
    final rows = await _db.select(_db.categories).get();
    return rows.map(_toModel).toList();
  }

  Future<CategoryModel> create({
    required String name,
    required String color,
    required String type,
  }) async {
    final id = await _db.into(_db.categories).insert(
          CategoriesCompanion.insert(
            name: name,
            color: Value(color),
            type: type,
          ),
        );
    return CategoryModel(id: id, name: name, color: color, type: type);
  }

  Future<CategoryModel> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) async {
    await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
      CategoriesCompanion(
        name: Value(name),
        color: Value(color),
        type: Value(type),
      ),
    );
    return CategoryModel(id: id, name: name, color: color, type: type);
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
  }

  CategoryModel _toModel(Category row) =>
      CategoryModel(id: row.id, name: row.name, color: row.color, type: row.type);
}

final categoryDaoProvider = Provider<CategoryDao>(
  (ref) => CategoryDao(ref.watch(appDatabaseProvider)),
);
