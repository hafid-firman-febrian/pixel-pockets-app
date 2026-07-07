import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

class TransactionDao {
  TransactionDao(this._db);

  final AppDatabase _db;

  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    final t = _db.transactions;
    final c = _db.categories;

    final query = _db.select(t).join([
      leftOuterJoin(c, c.id.equalsExp(t.categoryId)),
    ]);

    String? startDate = filter.startDate;
    String? endDate = filter.endDate;

    if (filter.salaryPeriodId != null) {
      final period = await (_db.select(_db.salaryPeriods)
            ..where((p) => p.id.equals(filter.salaryPeriodId!)))
          .getSingleOrNull();
      if (period != null) {
        startDate = period.startDate;
        endDate = period.endDate;
      }
    }

    if (startDate != null) {
      query.where(t.transactionDate.isBiggerOrEqualValue(startDate));
    }
    if (endDate != null) {
      query.where(t.transactionDate.isSmallerOrEqualValue(endDate));
    }
    if (filter.transactionType != null) {
      query.where(t.transactionType.equals(filter.transactionType!));
    }
    if (filter.categoryId != null) {
      query.where(t.categoryId.equals(filter.categoryId!));
    }

    query
      ..orderBy([
        OrderingTerm(expression: t.transactionDate, mode: OrderingMode.desc),
        OrderingTerm(expression: t.id, mode: OrderingMode.desc),
      ])
      ..limit(filter.limit, offset: (filter.page - 1) * filter.limit);

    final rows = await query.get();
    return rows.map((row) {
      final tx = row.readTable(t);
      final cat = row.readTableOrNull(c);
      return TransactionModel(
        id: tx.id,
        transactionDate: tx.transactionDate,
        transactionType: tx.transactionType,
        amount: tx.amount,
        categoryId: tx.categoryId,
        description: tx.description,
        categoryName: cat?.name,
        categoryColor: cat?.color,
        createdAt: tx.createdAt,
        updatedAt: tx.updatedAt,
      );
    }).toList();
  }

  Future<TransactionModel> create(TransactionModel m) async {
    final id = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            transactionDate: m.transactionDate,
            transactionType: m.transactionType,
            amount: m.amount,
            categoryId: Value(m.categoryId),
            description: Value(m.description),
          ),
        );
    return _byId(id);
  }

  Future<TransactionModel> update(TransactionModel m) async {
    await (_db.update(_db.transactions)..where((t) => t.id.equals(m.id))).write(
      TransactionsCompanion(
        transactionDate: Value(m.transactionDate),
        transactionType: Value(m.transactionType),
        amount: Value(m.amount),
        categoryId: Value(m.categoryId),
        description: Value(m.description),
      ),
    );
    return _byId(m.id);
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<TransactionModel> _byId(int id) async {
    final list = await getAll(TransactionFilter(page: 1, limit: 1000000));
    return list.firstWhere((t) => t.id == id);
  }
}

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => TransactionDao(ref.watch(appDatabaseProvider)),
);
