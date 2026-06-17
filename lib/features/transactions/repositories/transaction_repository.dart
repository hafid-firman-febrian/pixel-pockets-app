import 'package:dio/dio.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../models/transaction_filter.dart';
import '../models/transaction_model.dart';

/// All transaction API access lives here. Every method:
/// - unwraps the `"data"` envelope, and
/// - converts [DioException] into a UI-safe [Failure].
class TransactionRepository {
  TransactionRepository(this._dio);

  final Dio _dio;

  /// GET /api/transactions with date/type filters + pagination.
  Future<List<TransactionModel>> getAll(TransactionFilter filter) async {
    try {
      final response = await _dio.get(
        ApiEndpoints.transactions,
        queryParameters: filter.toQueryParameters(),
      );
      final list = response.data['data'] as List;
      return list
          .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  /// POST /api/transactions. [body] is a snake_case write payload
  /// (use [TransactionModel.toJson]).
  Future<TransactionModel> create(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post(ApiEndpoints.transactions, data: body);
      return TransactionModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  /// PUT /api/transactions/:id.
  Future<TransactionModel> update(int id, Map<String, dynamic> body) async {
    try {
      final response = await _dio.put(
        ApiEndpoints.transactionById(id),
        data: body,
      );
      return TransactionModel.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  /// DELETE /api/transactions/:id.
  Future<void> delete(int id) async {
    try {
      await _dio.delete(ApiEndpoints.transactionById(id));
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}
