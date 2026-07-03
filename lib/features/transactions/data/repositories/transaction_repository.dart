import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._remote, this._local);

  final TransactionRemoteDataSource _remote;
  final TransactionLocalDataSource _local;

  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    try {
      final dtos = await _remote.getAll(filter);
      await _local.save(filter, dtos);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      if (isConnectivityError(e)) {
        final cached = _local.read(filter);
        if (cached != null) return cached.map((d) => d.toDomain()).toList();
      }
      throw Failure.fromDio(e);
    }
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final dto = await _remote.create(
        TransactionDto.fromDomain(transaction).toJson(),
      );
      await _local.invalidateAfterMutation();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<TransactionModel> update(TransactionModel transaction) async {
    try {
      final dto = await _remote.update(
        transaction.id,
        TransactionDto.fromDomain(transaction).toJson(),
      );
      await _local.invalidateAfterMutation();
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
      await _local.invalidateAfterMutation();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepository(
    ref.watch(transactionRemoteDataSourceProvider),
    ref.watch(transactionLocalDataSourceProvider),
  ),
);
