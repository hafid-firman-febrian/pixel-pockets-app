import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/features/dashboard/application/services/dashboard_service.dart';
import 'package:pixel_pocket/features/dashboard/data/repositories/dashboard_repository.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/category_summary.dart';
import 'package:pixel_pocket/features/dashboard/domain/models/transaction_summary.dart';

CategorySummary _cat(String name, String type, double total) => CategorySummary(
  categoryId: name.hashCode,
  name: name,
  colorHex: '#000000',
  type: type,
  total: total,
  percentage: 0,
  count: 1,
);

class _FakeRepo implements DashboardRepository {
  _FakeRepo(this._byCategory);
  final List<CategorySummary> _byCategory;

  @override
  Future<List<CategorySummary>> getByCategory(int? periodId) async =>
      _byCategory;

  @override
  Future<TransactionSummary> getSummary(int? periodId) =>
      throw UnimplementedError();
}

void main() {
  test('expensesByCategory keeps only expenses, sorted by total desc',
      () async {
    final service = DashboardService(
      _FakeRepo([
        _cat('Salary', 'income', 2800000),
        _cat('Meal', 'expense', 20000),
        _cat('Beverage', 'expense', 750000),
        _cat('Cigarettes', 'expense', 30000),
      ]),
    );

    final result = await service.expensesByCategory(null);

    expect(result.map((c) => c.name).toList(), [
      'Beverage',
      'Cigarettes',
      'Meal',
    ]);
    expect(result.every((c) => c.type == 'expense'), isTrue);
  });

  test('expensesByCategory returns empty when there are no expenses', () async {
    final service = DashboardService(
      _FakeRepo([_cat('Salary', 'income', 2800000)]),
    );

    expect(await service.expensesByCategory(null), isEmpty);
  });
}
