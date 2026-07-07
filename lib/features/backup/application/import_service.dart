import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

class ImportResult {
  const ImportResult({
    required this.categories,
    required this.salaryPeriods,
    required this.transactions,
  });

  final int categories;
  final int salaryPeriods;
  final int transactions;
}

class ImportService {
  ImportService({
    required AppDatabase db,
    required CategoryRemoteDataSource categories,
    required SalaryPeriodRemoteDataSource salaryPeriods,
    required TransactionRemoteDataSource transactions,
  }) : _db = db,
       _categories = categories,
       _salaryPeriods = salaryPeriods,
       _transactions = transactions;

  final AppDatabase _db;
  final CategoryRemoteDataSource _categories;
  final SalaryPeriodRemoteDataSource _salaryPeriods;
  final TransactionRemoteDataSource _transactions;

  static const int _pageSize = 100;

  Future<ImportResult> importAll() async {
    final cats = await _categories.getAll();
    final periods = await _salaryPeriods.getAll();

    final txs = <TransactionDto>[];
    for (var page = 1; ; page++) {
      final batch = await _transactions.getAll(
        TransactionFilter(page: page, limit: _pageSize),
      );
      txs.addAll(batch);
      if (batch.length < _pageSize) break;
    }

    await _db.replaceAll(
      categories: [
        for (final c in cats)
          CategoriesCompanion.insert(
            id: Value(c.id),
            name: c.name,
            color: Value(c.color),
            type: c.type,
          ),
      ],
      salaryPeriods: [
        for (final p in periods)
          SalaryPeriodsCompanion.insert(
            id: Value(p.id),
            name: p.name,
            startDate: p.startDate,
            endDate: p.endDate,
            salaryAmount: Value(p.salaryAmount),
          ),
      ],
      transactions: [
        for (final t in txs)
          TransactionsCompanion.insert(
            id: Value(t.id),
            transactionDate: t.transactionDate,
            transactionType: t.transactionType,
            amount: t.amount,
            categoryId: Value(t.categoryId),
            description: Value(t.description),
            createdAt: Value(t.createdAt),
            updatedAt: Value(t.updatedAt),
          ),
      ],
    );

    return ImportResult(
      categories: cats.length,
      salaryPeriods: periods.length,
      transactions: txs.length,
    );
  }
}

final importServiceProvider = Provider<ImportService>(
  (ref) => ImportService(
    db: ref.watch(appDatabaseProvider),
    categories: ref.watch(categoryRemoteDataSourceProvider),
    salaryPeriods: ref.watch(salaryPeriodRemoteDataSourceProvider),
    transactions: ref.watch(transactionRemoteDataSourceProvider),
  ),
);
