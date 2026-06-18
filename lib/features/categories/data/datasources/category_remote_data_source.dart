import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixel_pocket/core/api/api_client.dart';
import 'package:pixel_pocket/core/api/api_endpoints.dart';
import 'package:pixel_pocket/features/categories/data/dtos/category_dto.dart';

/// Raw transport for categories. Unwraps the `"data"` envelope and returns
/// DTOs. Throws [DioException] on failure (mapped to Failure by the repo).
class CategoryRemoteDataSource {
  CategoryRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<CategoryDto>> getAll() async {
    final response = await _dio.get(ApiEndpoints.categories);
    final list = response.data['data'] as List;
    return list
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<CategoryDto>> seed() async {
    final response = await _dio.post(ApiEndpoints.categoriesSeed);
    final list = response.data['data'] as List;
    return list
        .map((e) => CategoryDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final categoryRemoteDataSourceProvider = Provider<CategoryRemoteDataSource>(
  (ref) => CategoryRemoteDataSource(ref.watch(dioProvider)),
);
