import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/error/failure.dart';
import 'package:pixel_pocket/features/transactions/data/datasources/transaction_remote_data_source.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_model.dart';



class TransactionRepository {
  TransactionRepository(this._remote);

  final TransactionRemoteDataSource _remote;

  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    try {
      final dtos = await _remote.getAll(filter);
      return dtos.map((d) => d.toDomain()).toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<TransactionModel> create(TransactionModel transaction) async {
    try {
      final dto = await _remote.create(
        TransactionDto.fromDomain(transaction).toJson(),
      );
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
      return dto.toDomain();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _remote.delete(id);
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) =>
      TransactionRepository(ref.watch(transactionRemoteDataSourceProvider)),
);
