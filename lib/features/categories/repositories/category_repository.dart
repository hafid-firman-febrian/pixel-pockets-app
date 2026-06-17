import 'package:dio/dio.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/error/failure.dart';
import '../models/category_model.dart';

/// All category API access. Unwraps the `"data"` envelope and converts
/// transport errors into [Failure].
class CategoryRepository {
  CategoryRepository(this._dio);

  final Dio _dio;

  Future<List<CategoryModel>> getAll() async {
    try {
      final response = await _dio.get(ApiEndpoints.categories);
      final list = response.data['data'] as List;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }

  /// Seeds the 18 default categories. Returns the resulting list.
  Future<List<CategoryModel>> seed() async {
    try {
      final response = await _dio.post(ApiEndpoints.categoriesSeed);
      final list = response.data['data'] as List;
      return list
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Failure.fromDio(e);
    }
  }
}
