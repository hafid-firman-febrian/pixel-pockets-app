import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/database/app_database.dart';
import 'package:pixel_pocket/features/backup/application/import_service.dart';
import 'package:pixel_pocket/features/categories/data/datasources/category_remote_data_source.dart';
import 'package:pixel_pocket/features/categories/data/dtos/category_dto.dart';
import 'package:pixel_pocket/features/salary_period/data/datasources/salary_period_remote_data_source.dart';
import 'package:pixel_pocket/features/salary_period/data/dtos/salary_period_dto.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

Dio _unusedDio() => Dio();

class _FakeCategories extends CategoryRemoteDataSource {
  _FakeCategories() : super(_unusedDio());
  @override
  Future<List<CategoryDto>> getAll() async => const [
    CategoryDto(id: 7, name: 'Food', color: '#111111', type: 'expense'),
  ];
}

class _FakeSalary extends SalaryPeriodRemoteDataSource {
  _FakeSalary() : super(_unusedDio());
  @override
  Future<List<SalaryPeriodDto>> getAll() async => const [
    SalaryPeriodDto(
      id: 3,
      name: 'Jul',
      startDate: '2026-07-01',
      endDate: '2026-07-31',
    ),
  ];
}

class _FakeTx extends TransactionRemoteDataSource {
  _FakeTx() : super(_unusedDio());
  @override
  Future<List<TransactionDto>> getAll(TransactionFilter filter) async {
    if (filter.page > 1) return const [];
    return const [
      TransactionDto(
        id: 99,
        transactionDate: '2026-07-05',
        transactionType: 'expense',
        amount: 12,
        categoryId: 7,
      ),
    ];
  }
}

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('imports preserving ids in FK-safe order', () async {
    final service = ImportService(
      db: db,
      categories: _FakeCategories(),
      salaryPeriods: _FakeSalary(),
      transactions: _FakeTx(),
    );
    final result = await service.importAll();
    expect(result.categories, 1);
    expect(result.salaryPeriods, 1);
    expect(result.transactions, 1);

    final cat = await db.select(db.categories).getSingle();
    expect(cat.id, 7);
    final tx = await db.select(db.transactions).getSingle();
    expect(tx.id, 99);
    expect(tx.categoryId, 7);
  });
}
