import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/transactions/data/dtos/transaction_dto.dart';
import 'package:pixel_pocket/features/transactions/domain/models/transaction_filter.dart';

class TransactionRemoteDataSource {
  TransactionRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<TransactionDto>> getAll(TransactionFilter filter) async {
    final response = await _dio.get(
      ApiEndpoints.transactions,
      queryParameters: _queryFrom(filter),
    );
    final list = response.data['data'] as List;
    return list
        .map((e) => TransactionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionDto> create(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiEndpoints.transactions, data: body);
    return TransactionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<TransactionDto> update(int id, Map<String, dynamic> body) async {
    final response = await _dio.put(
      ApiEndpoints.transactionById(id),
      data: body,
    );
    return TransactionDto.fromJson(
      response.data['data'] as Map<String, dynamic>,
    );
  }

  Future<void> delete(int id) async {
    await _dio.delete(ApiEndpoints.transactionById(id));
  }

  Map<String, dynamic> _queryFrom(TransactionFilter f) => {
    if (f.salaryPeriodId != null) 'salary_period_id': f.salaryPeriodId,
    if (f.filter != null) 'filter': f.filter,
    if (f.startDate != null) 'start_date': f.startDate,
    if (f.endDate != null) 'end_date': f.endDate,
    if (f.transactionType != null) 'transaction_type': f.transactionType,
    'page': f.page,
    'limit': f.limit,
  };
}

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>(
      (ref) => TransactionRemoteDataSource(ref.watch(dioProvider)),
    );
