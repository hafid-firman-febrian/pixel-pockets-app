import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/data/repositories/category_repository.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Business logic for categories.
class CategoryService {
  CategoryService(this._repo);

  final CategoryRepository _repo;

  Future<List<CategoryModel>> list() => _repo.getAll();
  Future<List<CategoryModel>> seed() => _repo.seed();

  Future<CategoryModel> create({
    required String name,
    required String color,
    required String type,
  }) => _repo.create(name: name, color: color, type: type);

  Future<CategoryModel> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) => _repo.update(id: id, name: name, color: color, type: type);

  Future<void> delete(int id) => _repo.delete(id);
}

final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(categoryRepositoryProvider)),
);
