import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_dao.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

class CategoryRepository {
  CategoryRepository(this._dao);

  final CategoryDao _dao;

  Future<List<CategoryModel>> getAll() => _dao.getAll();

  Future<CategoryModel> create({
    required String name,
    required String color,
    required String type,
  }) => _dao.create(name: name, color: color, type: type);

  Future<CategoryModel> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) => _dao.update(id: id, name: name, color: color, type: type);

  Future<void> delete(int id) => _dao.delete(id);
}

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(categoryDaoProvider)),
);
