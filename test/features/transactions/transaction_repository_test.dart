import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_pocket/core/cache/cache_store.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/data/repositories/transaction_repository.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeRemote implements TransactionRemoteDataSource {
  _FakeRemote({this.result, this.error});
  final List<TransactionDto>? result;
  final Object? error;

  @override
  Future<List<TransactionDto>> getAll(TransactionFilter filter) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<TransactionDto> create(Map<String, dynamic> body) async =>
      throw UnimplementedError();
  @override
  Future<TransactionDto> update(int id, Map<String, dynamic> body) async =>
      throw UnimplementedError();
  @override
  Future<void> delete(int id) async {}
}

DioException _offline() => DioException(
  requestOptions: RequestOptions(path: '/'),
  type: DioExceptionType.connectionError,
);

DioException _server500() {
  final o = RequestOptions(path: '/');
  return DioException(
    requestOptions: o,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: o, statusCode: 500),
  );
}

const _dto = TransactionDto(
  id: 1,
  transactionDate: '2026-07-01',
  transactionType: 'expense',
  amount: 25000,
);

void main() {
  const filter = TransactionFilter();
  late TransactionLocalDataSource local;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    local = TransactionLocalDataSource(
      CacheStore(await SharedPreferences.getInstance()),
    );
  });

  test('success returns fresh data AND writes to cache', () async {
    final repo = TransactionRepository(_FakeRemote(result: [_dto]), local);
    final result = await repo.getAll(filter);
    expect(result.single.amount, 25000);
    expect(local.read(filter)!.single.id, 1);
  });

  test('offline error with cache present returns cached data', () async {
    await local.save(filter, [_dto]);
    final repo = TransactionRepository(_FakeRemote(error: _offline()), local);
    final result = await repo.getAll(filter);
    expect(result.single.id, 1);
  });

  test('offline error with empty cache throws Failure', () async {
    final repo = TransactionRepository(_FakeRemote(error: _offline()), local);
    expect(() => repo.getAll(filter), throwsA(isA<Failure>()));
  });

  test(
    'server 500 throws even when cache is present (cache not used)',
    () async {
      await local.save(filter, [_dto]);
      final repo = TransactionRepository(
        _FakeRemote(error: _server500()),
        local,
      );
      expect(() => repo.getAll(filter), throwsA(isA<Failure>()));
    },
  );
}
