import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/application/services/category_service.dart';
import 'package:pixel_pocket/features/categories/presentation/states/category_state.dart';

/// Glue between the category form and the service: creates a category, then
/// invalidates [categoriesProvider] so every consumer refetches. Throws
/// [Failure] on error for the caller (the form) to surface.
class CategoryController {
  CategoryController(this._ref);

  final Ref _ref;

  Future<void> create({
    required String name,
    required String color,
    required String type,
  }) async {
    await _ref
        .read(categoryServiceProvider)
        .create(name: name, color: color, type: type);
    _ref.invalidate(categoriesProvider);
  }

  Future<void> update({
    required int id,
    required String name,
    required String color,
    required String type,
  }) async {
    await _ref
        .read(categoryServiceProvider)
        .update(id: id, name: name, color: color, type: type);
    _ref.invalidate(categoriesProvider);
  }

  Future<void> delete(int id) async {
    await _ref.read(categoryServiceProvider).delete(id);
    _ref.invalidate(categoriesProvider);
  }
}

final categoryControllerProvider = Provider<CategoryController>(
  (ref) => CategoryController(ref),
);
