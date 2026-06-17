import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../models/category_model.dart';
import '../repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => CategoryRepository(ref.watch(dioProvider)),
);

/// All categories. Kept alive so the transaction form can read it cheaply.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(categoryRepositoryProvider).getAll();
});

/// Only expense categories — convenience for filtered pickers.
final expenseCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isExpense).toList();
});

/// Only income categories.
final incomeCategoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final all = await ref.watch(categoriesProvider.future);
  return all.where((c) => c.isIncome).toList();
});
