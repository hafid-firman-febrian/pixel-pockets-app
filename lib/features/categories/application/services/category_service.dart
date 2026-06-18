import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/data/repositories/category_repository.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// Business logic for categories.
class CategoryService {
  CategoryService(this._repo);

  final CategoryRepository _repo;

  Future<List<CategoryModel>> list() => _repo.getAll();
  Future<List<CategoryModel>> seed() => _repo.seed();
}

final categoryServiceProvider = Provider<CategoryService>(
  (ref) => CategoryService(ref.watch(categoryRepositoryProvider)),
);
