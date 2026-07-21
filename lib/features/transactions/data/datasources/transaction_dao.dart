import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/core/error/failure.dart';
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
    return rows.map(_toModel).toList();
  }

  Future<TransactionModel> create(TransactionModel m) async {
    final now = DateTime.now().toIso8601String();
    final id = await _db.into(_db.transactions).insert(
          TransactionsCompanion.insert(
            transactionDate: m.transactionDate,
            transactionType: m.transactionType,
            amount: m.amount,
            categoryId: Value(m.categoryId),
            description: Value(m.description),
            createdAt: Value(now),
            updatedAt: Value(now),
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
        updatedAt: Value(DateTime.now().toIso8601String()),
      ),
    );
    return _byId(m.id);
  }

  Future<void> delete(int id) async {
    await (_db.delete(_db.transactions)..where((t) => t.id.equals(id))).go();
  }

  Future<TransactionModel> _byId(int id) async {
    final t = _db.transactions;
    final c = _db.categories;

    final row = await (_db.select(t).join([
      leftOuterJoin(c, c.id.equalsExp(t.categoryId)),
    ])..where(t.id.equals(id)))
        .getSingleOrNull();

    if (row == null) {
      throw const Failure(
        message: 'Transaction not found.',
        type: FailureType.notFound,
      );
    }
    return _toModel(row);
  }

  TransactionModel _toModel(TypedResult row) {
    final tx = row.readTable(_db.transactions);
    final cat = row.readTableOrNull(_db.categories);
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
  }
}

final transactionDaoProvider = Provider<TransactionDao>(
  (ref) => TransactionDao(ref.watch(appDatabaseProvider)),
);
