import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/features/categories/application/services/category_service.dart';
import 'package:pixel_pocket/features/categories/domain/models/category_model.dart';

/// All categories. Read by the transaction form.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryServiceProvider).list();
});

/// Only expense categories — convenience for filtered pickers.
final expenseCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isExpense).toList();
});

/// Only income categories.
final incomeCategoriesProvider =
    FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isIncome).toList();
});
